@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';

import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

import '../support/fakes.dart';
import '../support/synthetic_alignment.dart';
import '../support/test_app.dart';

/// Renders each reference state at the reference geometry (540 × 1170 px) so
/// that it can be compared side by side with docs/design/reference/
/// (see tool/compare_with_references.py). The system status and navigation
/// bars are drawn by the OS, so they are blank here.
void main() {
  Future<void> shot(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screens/$name.png'),
  );

  for (final locale in ['en', 'ar']) {
    testWidgets('splash $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.splash);
      await shot('splash_$locale');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
    });

    testWidgets('01 home $locale', (tester) async {
      await pumpApp(tester, locale: locale);
      await shot('01_home_$locale');
    });

    testWidgets('01 home $locale scrolled', (tester) async {
      await pumpApp(tester, locale: locale);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await shot('01_home_${locale}_scrolled');
    });

    testWidgets('02 drawer $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      await tester.tap(
        find.byTooltip(
          locale == 'en' ? 'Open navigation menu' : 'فتح قائمة التنقل',
        ),
      );
      await tester.pumpAndSettle();
      await shot('02_drawer_$locale');
    });

    testWidgets('03 reader $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      await shot('03_reader_$locale');
    });

    testWidgets('04 ayah selected $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      await tester.longPressAt(ayahCentre(tester, 6));
      // First frame only: the highlight is applied and the sheet hasn't animated in.
      await tester.pump();
      await shot('04_ayah_selected_$locale');
      await tester.pumpAndSettle();
    });

    testWidgets('05 ayah sheet $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      await tester.longPressAt(ayahCentre(tester, 6));
      await tester.pumpAndSettle();
      await shot('05_ayah_sheet_$locale');
    });

    testWidgets('06 overflow menu $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      await tester.tap(
        find.byTooltip(locale == 'en' ? 'More options' : 'خيارات إضافية'),
      );
      await tester.pumpAndSettle();
      await shot('06_menu_$locale');
    });

    testWidgets('home $locale at 200% text', (tester) async {
      await pumpApp(tester, locale: locale, textScale: 2.0);
      await shot('home_${locale}_text200');
    });
  }

  // Phase 1, increment 2 screens (no supplied references; concept board).
  const preview = {'debug.designPreview': true};
  for (final locale in ['en', 'ar']) {
    testWidgets('index (shipped state) $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.quranIndex);
      await shot('index_$locale');
    });

    testWidgets('library empty $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.library);
      await shot('library_empty_$locale');
    });

    testWidgets('library preview $locale', (tester) async {
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.library,
        extraPrefs: preview,
      );
      await shot('library_preview_$locale');
    });

    testWidgets('book details preview $locale', (tester) async {
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.book('preview-1'),
        extraPrefs: preview,
      );
      await shot('book_details_preview_$locale');
    });

    testWidgets('settings $locale', (tester) async {
      await pumpApp(tester, locale: locale, location: AppRoutes.settings);
      await shot('settings_$locale');
    });
  }

  testWidgets('content sources en', (tester) async {
    await pumpApp(tester, location: AppRoutes.contentSources);
    await shot('content_sources_en');
  });

  testWidgets('library preview en at 200% text', (tester) async {
    await pumpApp(
      tester,
      location: AppRoutes.library,
      extraPrefs: preview,
      textScale: 2.0,
    );
    await shot('library_preview_en_text200');
  });

  // Al-Fatiha with the Tafsir player (real R3 alignment: no reviewed spans).
  for (final locale in ['en', 'ar']) {
    testWidgets('fatiha player ready $locale', (tester) async {
      final player = FakeTafsirPlayer();
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.quran,
        recording: const RecordingReady('/fake/r3.mp3', fatihaTafsirR3),
        player: player,
      );
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      player.setPosition(const Duration(minutes: 3, seconds: 12));
      await tester.pump();
      await tester.pump();
      await shot('fatiha_player_r3_pending_$locale');
    });

    // SYNTHETIC test mapping (fake recording hash, invented times). These
    // images show how verified highlighting looks; they are not R3 results.
    testWidgets('fatiha sync demo synthetic $locale', (tester) async {
      final player = FakeTafsirPlayer();
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.quran,
        recording: const RecordingReady(
          '/fake/synthetic.mp3',
          syntheticRecording,
        ),
        player: player,
        overrides: [
          alignmentProvider.overrideWith(
            (ref, asset) async => syntheticAlignment(),
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      player.setPosition(const Duration(milliseconds: 45000)); // explaining 2
      await tester.pump();
      await tester.pump();
      await shot('fatiha_sync_SYNTHETIC_explaining_$locale');
      player.setPosition(const Duration(milliseconds: 6000)); // reading 1
      await tester.pump();
      await tester.pump();
      await shot('fatiha_sync_SYNTHETIC_reading_$locale');
    });
  }

  testWidgets('reader light mode en', (tester) async {
    await pumpApp(tester, location: AppRoutes.quran, readerDark: false);
    await shot('reader_light_en');
  });

  // Representative Mushaf pages (page boundaries from the verified data):
  // Al-Fatiha; Al-Baqarah's first page; a page inside a long surah;
  // At-Tawbah's first page (a surah start without a basmala); At-Tin (the
  // "بِّسْمِ" basmala variant) followed by the start of Al-Alaq; the last
  // page (three short surahs). Every page's content is checked in
  // test/quran/all_pages_test.dart.
  for (final (page, name, locale, dark) in [
    (1, 'fatiha', 'en', true),
    (2, 'baqarah_start', 'ar', true),
    (50, 'baqarah_inside', 'en', false),
    (187, 'tawbah_start', 'en', true),
    (597, 'tin_basmala_variant', 'ar', false),
    (604, 'last_page', 'en', true),
  ]) {
    testWidgets('mushaf page $page $name $locale', (tester) async {
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.quranPage(page),
        readerDark: dark,
      );
      await shot('page_${page.toString().padLeft(3, '0')}_${name}_$locale');
    });
  }

  testWidgets('mushaf page 604 small phone, 130% text', (tester) async {
    await pumpApp(
      tester,
      location: AppRoutes.quranPage(604),
      physicalSize: const Size(640, 1280),
      dpr: 2,
      textScale: 1.3,
    );
    await shot('page_604_small_phone_130');
  });

  testWidgets('home on a 360 dp phone en', (tester) async {
    await pumpApp(tester, physicalSize: const Size(1080, 2340), dpr: 3);
    await shot('home_en_360dp');
  });
}
