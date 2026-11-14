import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_metadata.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/mushaf_page.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/surah_text_view.dart';

import '../support/rendered_numbering.dart';
import '../support/test_app.dart';

/// All 604 Madinah Mushaf pages as rendered by the reader: each page shows
/// exactly its ayahs (verbatim, in order), every number right after its own
/// ayah, a surah header and basmala only where a surah starts (none for
/// At-Tawbah), and its own page number, at several screen sizes and text
/// scales, with no layout overflow.
void main() {
  setUpAll(loadAppFonts);

  final meta = parseQuranMetadata(
    File(BundledQuranMetadataRepository.assetPath).readAsStringSync(),
  )!;
  final surahs = <int, SurahText>{
    for (var n = 1; n <= 114; n++)
      n: parseSurahAsset(
        File(BundledQuranTextRepository.assetPath(n)).readAsStringSync(),
      )!,
  };

  Finder pageFinder(int page) =>
      find.byWidgetPredicate((w) => w is MushafPage && w.page == page);

  RenderParagraph paragraphOf(int page, int surah) =>
      find
              .descendant(
                of: find.descendant(
                  of: pageFinder(page),
                  matching: find.byWidgetPredicate(
                    (w) => w is SurahTextView && w.surah.number == surah,
                  ),
                ),
                matching: find.descendant(
                  of: find.byKey(const ValueKey('quran-text')),
                  matching: find.byType(RichText),
                ),
              )
              .evaluate()
              .first
              .renderObject!
          as RenderParagraph;

  List<String> checkPage(WidgetTester tester, int page) {
    final problems = <String>[];
    final segments = meta.pageSegments(page);
    final shown = tester
        .widgetList<SurahTextView>(
          find.descendant(
            of: pageFinder(page),
            matching: find.byType(SurahTextView),
          ),
        )
        .map((v) => PageSegment(v.surah.number, v.firstAyah, v.lastAyah!))
        .toList();
    if (shown.toString() != segments.toString()) {
      problems.add('page $page shows $shown, expected $segments');
      return problems;
    }
    for (final seg in segments) {
      problems.addAll(
        checkRenderedNumbering(
          tester,
          surahs[seg.surah]!,
          paragraph: paragraphOf(page, seg.surah),
          first: seg.firstAyah,
          last: seg.lastAyah,
        ).map((p) => 'page $page: $p'),
      );
    }
    final headings = find
        .descendant(
          of: pageFinder(page),
          matching: find.byKey(const ValueKey('basmala-heading')),
        )
        .evaluate()
        .length;
    final expectedHeadings = segments
        .where((s) => s.startsSurah && surahs[s.surah]!.basmalaHeading != null)
        .length;
    if (headings != expectedHeadings) {
      problems.add('page $page: $headings basmala headings');
    }
    for (final seg in segments.where((s) => s.startsSurah)) {
      final title = 'سورة ${surahs[seg.surah]!.nameArabic}';
      if (find
          .descendant(of: pageFinder(page), matching: find.text(title))
          .evaluate()
          .isEmpty) {
        problems.add('page $page: no header for surah ${seg.surah}');
      }
    }
    final number = tester.widget<Text>(
      find.descendant(
        of: find.descendant(
          of: pageFinder(page),
          matching: find.byKey(const ValueKey('page-number')),
        ),
        matching: find.byType(Text),
      ),
    );
    if (number.data != AyahLayout.digits(page)) {
      problems.add('page $page: shows page number ${number.data}');
    }
    return problems;
  }

  Future<void> walkAllPages(WidgetTester tester) async {
    final problems = <String>[];
    final controller = tester
        .widget<PageView>(find.byKey(const ValueKey('mushaf-pages')))
        .controller!;
    for (var page = 1; page <= 604; page++) {
      controller.jumpToPage(page - 1);
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) problems.add('page $page: $error');
      problems.addAll(checkPage(tester, page));
    }
    expect(problems, isEmpty);
  }

  testWidgets('all 604 pages, phone (384 × 832 dp)', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranPage(1));
    await walkAllPages(tester);
  });

  testWidgets('all 604 pages, small phone (320 × 640 dp), Arabic, 130% text', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: 'ar',
      location: AppRoutes.quranPage(1),
      physicalSize: const Size(320 * 2.0, 640 * 2.0),
      dpr: 2.0,
      textScale: 1.3,
    );
    await walkAllPages(tester);
  });

  testWidgets('all 604 pages, tablet (800 × 1280 dp), largest Quran text', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: AppRoutes.quranPage(1),
      physicalSize: const Size(800 * 2.0, 1280 * 2.0),
      dpr: 2.0,
      extraPrefs: const {'quran.fontSize': 40.0},
    );
    await walkAllPages(tester);
  });

  testWidgets('At-Tawbah starts its page without a basmala', (tester) async {
    final page = meta.pageOf(9, 1)!;
    await pumpApp(tester, location: AppRoutes.quranPage(page));
    final tawbah = find.byWidgetPredicate(
      (w) => w is SurahTextView && w.surah.number == 9,
    );
    expect(tawbah, findsOneWidget);
    expect(
      find.descendant(
        of: tawbah,
        matching: find.byKey(const ValueKey('basmala-heading')),
      ),
      findsNothing,
    );
    expect(surahs[9]!.basmalaHeading, isNull);
  });

  testWidgets('Al-Fatiha page: the basmala is ayah 1, numbered', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranPage(1));
    expect(find.byKey(const ValueKey('basmala-heading')), findsNothing);
    expect(meta.pageSegments(1), [const PageSegment(1, 1, 7)]);
    expect(checkPage(tester, 1), isEmpty);
  });
}
