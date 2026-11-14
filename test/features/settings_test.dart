import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/library/presentation/library_screen.dart';
import 'package:sheekhcali/features/settings/presentation/content_sources_screen.dart';
import 'package:sheekhcali/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('Hijri adjustment: live preview, persisted, applied on Home', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.settings);
    expect(find.text('Umm al-Qura (provisional)'), findsOneWidget);
    expect(find.text('Today: 2 Jumada al-Thani 1448 AH'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    expect(find.text('Today: 3 Jumada al-Thani 1448 AH'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('hijri.adjustment'), 1);
  });

  testWidgets('Home shows the adjusted Hijri date', (tester) async {
    await pumpApp(tester, extraPrefs: {'hijri.adjustment': -1});
    expect(find.text('1 Jumada al-Thani 1448 AH'), findsOneWidget);
  });

  testWidgets('Wi-Fi only is stored and says when it applies', (tester) async {
    await pumpApp(tester, location: AppRoutes.settings);
    await tester.scrollUntilVisible(find.text('Download on Wi-Fi only'), 100);
    await tester.ensureVisible(find.text('Download on Wi-Fi only'));
    await tester.pumpAndSettle();
    expect(find.text('Applies once downloads are available.'), findsOneWidget);
    await tester.tap(find.text('Download on Wi-Fi only'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('downloads.wifiOnly'), isFalse);
  });

  testWidgets('content sources say plainly what is and is not installed', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.contentSources);
    expect(find.byType(ContentSourcesScreen), findsOneWidget);
    // Only the translation is still awaiting a source.
    expect(
      find.text('Not installed yet · source awaiting approval'),
      findsOneWidget,
    );
    expect(
      find.text(
        'All 114 surahs · Tanzil Uthmani 1.1, verbatim · cross-checked with a '
        'second source · reviewer check pending',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Tanzil metadata 1.0 · 114 surahs, 30 juz, 604 Madinah Mushaf pages · '
        'cross-checked with a second source',
      ),
      findsOneWidget,
    );
    expect(find.text('None published yet'), findsOneWidget);
    await tester.tap(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('debug: design preview switch drives the Library', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.settings);
    await tester.scrollUntilVisible(find.text('Design preview data'), 100);
    await tester.tap(find.text('Design preview data'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('debug.designPreview'), isTrue);
  });

  testWidgets('library shows preview books once the switch is on', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: AppRoutes.library,
      extraPrefs: {'debug.designPreview': true},
    );
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(BookRow), findsWidgets);
  });

  testWidgets('Arabic: signed Arabic-Indic segments and RTL', (tester) async {
    await pumpApp(tester, locale: 'ar', location: AppRoutes.settings);
    expect(find.text('+١'), findsOneWidget);
    expect(find.text('−٢'), findsOneWidget);
    expect(find.text('أم القرى (مؤقتًا)'), findsOneWidget);
    final ctx = tester.element(find.byType(SettingsScreen));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('$locale: no overflow at 200% text', (tester) async {
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.settings,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
