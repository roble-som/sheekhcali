import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/home/presentation/home_screen.dart';
import 'package:sheekhcali/features/navigation/presentation/app_drawer.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/core/text/search_folding.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';
import 'package:sheekhcali/features/quran/presentation/quran_search_screen.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/surah_text_view.dart';
import 'package:sheekhcali/features/settings/presentation/about_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';
import '../support/synthetic_alignment.dart';
import '../support/test_app.dart';

/// Reader features beyond Al-Fatiha: other surahs, bookmarks, text size,
/// continue reading, surah navigation, search and About.
void main() {
  setUpAll(loadAppFonts);
  final baqarah = parseSurahAsset(
    File(BundledQuranTextRepository.assetPath(2)).readAsStringSync(),
  )!;

  QuranReaderScreen reader(WidgetTester tester) =>
      tester.widget<QuranReaderScreen>(find.byType(QuranReaderScreen));

  testWidgets('surah 2: basmala as heading, ayah 1 without it', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranAt(2));
    final heading = tester.widget<Text>(
      find.byKey(const ValueKey('basmala-heading')),
    );
    expect(heading.data, baqarah.basmalaHeading);
    final spans = renderedAyahSpans(tester).map((e) => e.$1).toList();
    expect(spans.first, baqarah.ayahs.first.displayText);
    expect(spans.first, isNot(contains(baqarah.basmalaHeading!)));
  });

  testWidgets('tapping an ayah outside Al-Fatiha never plays audio', (
    tester,
  ) async {
    final player = FakeTafsirPlayer();
    await pumpApp(tester, location: AppRoutes.quranAt(2), player: player);
    await tester.tapAt(ayahCentreIn(tester, baqarah, 3));
    await tester.pumpAndSettle();
    expect(player.commands, isEmpty);
    expect(
      find.text(
        "The Sheikh's Tafsir recording is available for Al-Fatiha only, so far.",
      ),
      findsOneWidget,
    );
    // The tapped ayah is selected, and it is the one tapped.
    final highlighted = [
      for (final (text, bg) in renderedAyahSpans(tester))
        if (bg != null) text,
    ];
    expect(highlighted, [baqarah.ayahs[2].displayText]);
  });

  testWidgets('bookmark an ayah, find it in Bookmarks, open it, remove it', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranAt(2));
    await tester.longPressAt(ayahCentreIn(tester, baqarah, 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmark'));
    await tester.pumpAndSettle();
    expect(find.text('Bookmark added'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('quran.bookmarks'), ['2:2']);

    // The toolbar bookmark button opens the Bookmarks tab.
    await tester.tap(find.byTooltip('Bookmark page'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bookmark-2:2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bookmark-2:2')));
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 2);
    expect(reader(tester).initialAyah, 2);

    // Long press again: the sheet now offers removal.
    await tester.longPressAt(ayahCentreIn(tester, baqarah, 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove bookmark'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('quran.bookmarks'), isEmpty);
  });

  testWidgets('text size: controls sheet changes and saves the size', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quranAt(112));
    // Text.rich wraps the Quran span in the ambient default style.
    double size() => (quranParagraph(tester).text as TextSpan)
        .children!
        .first
        .style!
        .fontSize!;
    expect(size(), 28);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Controls'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('text-size-larger')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('quran.fontSize'), 30);
    Navigator.of(tester.element(find.byType(QuranReaderScreen))).pop();
    await tester.pumpAndSettle();
    expect(size(), 30);
  });

  testWidgets('continue reading: Home opens the last ayah read', (
    tester,
  ) async {
    await pumpApp(tester, extraPrefs: {'quran.lastRead': '2:255'});
    await tester.tap(find.text('Quran'));
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 2);
    expect(reader(tester).initialAyah, 255);
    // Opened at that ayah: it starts near the top of the reading area.
    final top = tester
        .state<SurahTextViewState>(find.byType(SurahTextView))
        .ayahGlobalTop(255)!;
    expect(top.dy, inInclusiveRange(0, 400));
  });

  testWidgets('drawer "Recent page" opens the last ayah read', (tester) async {
    await pumpApp(tester, extraPrefs: {'quran.lastRead': '36:12'});
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppDrawer),
        matching: find.text('Recent Page'),
      ),
    );
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 36);
    expect(reader(tester).initialAyah, 12);
  });

  testWidgets('tapping an ayah records the reading place', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranAt(2));
    await tester.tapAt(ayahCentreIn(tester, baqarah, 4));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quran.lastRead'), '2:4');
  });

  testWidgets('next and previous surah', (tester) async {
    await pumpApp(tester, location: AppRoutes.quranAt(113));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('next-surah')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('next-surah')));
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 114);
    expect(find.byKey(const ValueKey('next-surah')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('previous-surah')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('previous-surah')));
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 113);
  });

  test('search ignores marks and finds the ayah', () {
    final ikhlas = parseSurahAsset(
      File(BundledQuranTextRepository.assetPath(112)).readAsStringSync(),
    )!;
    final corpus = [
      for (final s in [baqarah, ikhlas])
        for (final a in s.ayahs)
          SearchableAyah(
            s.number,
            a.number,
            a.displayText,
            foldForSearch(a.displayText),
          ),
    ];
    // A word taken from the text itself; the search folds away its marks.
    final word = ikhlas.ayahs[1].displayText.split(' ').last;
    final results = searchQuran(corpus, word);
    expect(results.map((r) => '${r.surah}:${r.ayah}'), contains('112:2'));
    // Shown text is the stored text, unchanged.
    expect(
      results.firstWhere((r) => r.surah == 112).text,
      ikhlas.ayahs[1].displayText,
    );
    expect(searchQuran(corpus, 'x'), isEmpty); // too short
  });

  testWidgets('search screen: results open the reader at the ayah', (
    tester,
  ) async {
    final ikhlas = parseSurahAsset(
      File(BundledQuranTextRepository.assetPath(112)).readAsStringSync(),
    )!;
    await pumpApp(tester, location: AppRoutes.quranSearch);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pumpAndSettle();
    final word = ikhlas.ayahs[1].displayText.split(' ').last;
    await tester.enterText(
      find.byKey(const ValueKey('quran-search-field')),
      word,
    );
    await tester.pumpAndSettle();
    final result = find.byKey(const ValueKey('result-112:2'));
    await tester.scrollUntilVisible(
      result,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(reader(tester).surah, 112);
    expect(reader(tester).initialAyah, 2);
  });

  testWidgets('About: version, contents and licences', (tester) async {
    await pumpApp(tester, location: AppRoutes.about);
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    await tester.ensureVisible(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('drawer About opens the About screen', (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final about = find.descendant(
      of: find.byType(AppDrawer),
      matching: find.text('About'),
    );
    // The drawer list builds rows lazily: scroll until the row exists, then
    // bring it fully into view.
    await tester.scrollUntilVisible(
      about,
      100,
      scrollable: find.descendant(
        of: find.byType(AppDrawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(about);
    await tester.pumpAndSettle();
    await tester.tap(about);
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  for (final locale in ['en', 'ar']) {
    for (final location in [
      AppRoutes.about,
      AppRoutes.quranSearch,
      AppRoutes.quranIndexTab('bookmarks'),
      AppRoutes.quranAt(2),
    ]) {
      testWidgets('$locale $location: no overflow at 200% text', (
        tester,
      ) async {
        await pumpApp(
          tester,
          locale: locale,
          location: location,
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// Centre of the first glyph run of [ayah] in the reader's paragraph.
Offset ayahCentreIn(WidgetTester tester, SurahText surah, int ayah) {
  final p = quranParagraph(tester);
  final slot = AyahLayout(surah).slots.firstWhere((s) => s.number == ayah);
  final box = p
      .getBoxesForSelection(
        TextSelection(baseOffset: slot.text.start, extentOffset: slot.text.end),
      )
      .first
      .toRect();
  return p.localToGlobal(box.center);
}
