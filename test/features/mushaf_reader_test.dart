import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/mushaf_page.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/surah_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_app.dart';

/// The page reader: navigation by page, swipe, go to page, layout switch,
/// and the reading place. Page numbers come from the verified metadata.
void main() {
  setUpAll(loadAppFonts);
  final meta = parseQuranMetadata(
    File(BundledQuranMetadataRepository.assetPath).readAsStringSync(),
  )!;

  int shownPage(WidgetTester tester) =>
      tester.widget<MushafPage>(find.byType(MushafPage)).page;

  /// The vertical scroll view of the page on screen.
  Finder pageScroll(WidgetTester tester) => find.descendant(
    of: find.byKey(ValueKey('page-scroll-${shownPage(tester)}')),
    matching: find.byType(Scrollable),
  );

  Future<String?> lastRead() async =>
      (await SharedPreferences.getInstance()).getString('quran.lastRead');

  testWidgets('opens on the page holding the requested ayah', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranAt(2, 255));
    final page = meta.pageOf(2, 255)!;
    expect(shownPage(tester), page);
    // The ayah is scrolled near the top of the page.
    final top = tester
        .state<MushafPageState>(find.byType(MushafPage))
        .textOf(2)!
        .ayahGlobalTop(255)!;
    expect(top.dy, inInclusiveRange(0, 400));
    expect(await lastRead(), '2:255');
  });

  testWidgets('next and previous page buttons; the place follows', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranPage(50));
    final next = find.byKey(const ValueKey('next-page'));
    await tester.scrollUntilVisible(next, 300, scrollable: pageScroll(tester));
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(shownPage(tester), 51);
    final first = meta.pageSegments(51).first;
    expect(await lastRead(), '${first.surah}:${first.firstAyah}');

    final previous = find.byKey(const ValueKey('previous-page'));
    await tester.scrollUntilVisible(
      previous,
      300,
      scrollable: pageScroll(tester),
    );
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(shownPage(tester), 50);
  });

  testWidgets('first and last pages have no page beyond them', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranPage(1));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('previous-page')),
      300,
      scrollable: pageScroll(tester),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('previous-page')))
          .onPressed,
      isNull,
    );
    await pumpApp(tester, location: AppRoutes.quranPage(604));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('next-page')),
      300,
      scrollable: pageScroll(tester),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('next-page')))
          .onPressed,
      isNull,
    );
  });

  for (final locale in ['en', 'ar']) {
    testWidgets(
      '$locale: swiping right turns to the next page, as in a Mushaf',
      (tester) async {
        await pumpApp(tester, locale: locale, location: AppRoutes.quranPage(2));
        await tester.fling(
          find.byKey(const ValueKey('mushaf-pages')),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(shownPage(tester), 3);
        await tester.fling(
          find.byKey(const ValueKey('mushaf-pages')),
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(shownPage(tester), 2);
      },
    );
  }

  Future<void> openGoToPage(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go To Page'));
    await tester.pumpAndSettle();
  }

  testWidgets('go to page: valid, invalid and Arabic-Indic input', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranPage(1));
    await openGoToPage(tester);
    for (final bad in ['0', '605', 'abc', '']) {
      await tester.enterText(
        find.byKey(const ValueKey('go-to-page-field')),
        bad,
      );
      await tester.tap(find.byKey(const ValueKey('go-to-page-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a page number from 1 to 604.'), findsOneWidget);
    }
    await tester.enterText(
      find.byKey(const ValueKey('go-to-page-field')),
      '٣٠٠',
    );
    await tester.tap(find.byKey(const ValueKey('go-to-page-submit')));
    await tester.pumpAndSettle();
    expect(shownPage(tester), 300);

    await openGoToPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('go-to-page-field')),
      '604',
    );
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(shownPage(tester), 604);
  });

  testWidgets('a page number is never taken for an ayah number', (
    tester,
  ) async {
    // Page 255 is not ayah 2:255.
    await pumpApp(tester, location: AppRoutes.quranPage(255));
    final first = meta.pageSegments(255).first;
    expect(shownPage(tester), 255);
    expect(await lastRead(), '${first.surah}:${first.firstAyah}');
    expect(meta.pageOf(2, 255), isNot(255));
  });

  testWidgets('layout switch: whole surah and back, saved', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranAt(36, 12));
    expect(shownPage(tester), meta.pageOf(36, 12));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Controls'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whole surah'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quran.layout'), 'surah');
    Navigator.of(tester.element(find.byType(QuranReaderScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(MushafPage), findsNothing);
    await tester.scrollUntilVisible(find.byType(SurahNavigation), 500);
    expect(
      tester.widget<SurahNavigation>(find.byType(SurahNavigation)).surah,
      36,
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Controls'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pages'));
    await tester.pumpAndSettle();
    expect(prefs.getString('quran.layout'), 'pages');
    Navigator.of(tester.element(find.byType(QuranReaderScreen))).pop();
    await tester.pumpAndSettle();
    // Back on pages, at the place reached while reading the whole surah
    // (scrolled to its end above), not where the reader first opened.
    final place = (await lastRead())!.split(':').map(int.parse).toList();
    expect(place[0], 36);
    expect(shownPage(tester), meta.pageOf(place[0], place[1]));
  });

  testWidgets('juz index row opens the page where the juz starts', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranIndexTab('juz'));
    final row = find.byKey(const ValueKey('juz-row-2'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    final j = meta.juzs[1];
    expect(shownPage(tester), meta.pageOf(j.startSurah, j.startAyah));
  });

  testWidgets('continue reading after a restart reopens the same page', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranPage(400));
    final saved = await lastRead();
    // A restart: a fresh app with the stored preferences.
    await pumpApp(
      tester,
      location: AppRoutes.continueReading,
      extraPrefs: {'quran.lastRead': saved!},
    );
    expect(shownPage(tester), 400);
  });

  testWidgets('header names the surah and juz of the page', (tester) async {
    final page = meta.pageOf(18, 1)!;
    await pumpApp(tester, location: AppRoutes.quranPage(page));
    final header = find.byKey(const ValueKey('page-header'));
    expect(
      find.descendant(of: header, matching: find.textContaining('Al-Kahf')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.text('Juz ${meta.juzOf(18, 1)}'),
      ),
      findsOneWidget,
    );
  });
}
