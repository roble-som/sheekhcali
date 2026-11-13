import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/app.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/providers.dart';
import 'package:sheekhcali/features/tafsir_audio/application/tafsir_player.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// The reference screenshots' date: Thursday 12 November 2026.
final referenceDate = DateTime(2026, 11, 12, 7, 59);

/// Reference screenshot geometry: 540 × 1170 px at an assumed 1.40625 px/dp,
/// so 384 × 832 dp, with a 50 px status bar and a 67.5 px navigation bar.
const referencePhysicalSize = Size(540, 1170);
const referenceDpr = 1.40625;

bool _fontsLoaded = false;

/// Loads the bundled fonts and the Material icon font so that widget and
/// golden tests render real glyphs instead of the test font.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await load('NotoSansArabic', [
    'assets/fonts/NotoSansArabic-Regular.ttf',
    'assets/fonts/NotoSansArabic-Medium.ttf',
    'assets/fonts/NotoSansArabic-SemiBold.ttf',
    'assets/fonts/NotoSansArabic-Bold.ttf',
  ]);
  await load('AmiriQuranText', ['assets/fonts/Amiri-Regular.ttf']);
  await load('NotoNaskhArabic', [
    'assets/fonts/NotoNaskhArabic-Regular.ttf',
    'assets/fonts/NotoNaskhArabic-SemiBold.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  }
  _fontsLoaded = true;
}

/// Pumps the whole app at the reference geometry.
Future<void> pumpApp(
  WidgetTester tester, {
  String locale = 'en',
  String location = AppRoutes.home,
  double textScale = 1.0,
  bool readerDark = true,
  Size physicalSize = referencePhysicalSize,
  double dpr = referenceDpr,
  Map<String, Object> extraPrefs = const {},
  List<Override> overrides = const [],
  RecordingStatus recording = const RecordingNotInstalled('/test/dev-media'),
  TafsirPlayer? player,
}) async {
  await loadAppFonts();
  SharedPreferences.setMockInitialValues({
    'ui.locale': locale,
    'reader.dark': readerDark,
    ...extraPrefs,
  });
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = const FakeViewPadding(top: 50, bottom: 67.5);
  tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 67.5);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => referenceDate),
        initialLocationProvider.overrideWithValue(location),
        splashMinDurationProvider.overrideWithValue(
          const Duration(milliseconds: 400),
        ),
        recordingRepositoryProvider.overrideWithValue(
          FakeRecordingRepository(recording),
        ),
        tafsirPlayerProvider.overrideWithValue(player ?? FakeTafsirPlayer()),
        ...overrides,
      ],
      child: const SheekhCalinuurApp(),
    ),
  );
  await tester.pumpAndSettle();
}
