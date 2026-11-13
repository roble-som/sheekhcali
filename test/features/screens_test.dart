import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/theme/app_colors.dart';
import 'package:sheekhcali/features/home/presentation/home_screen.dart';
import 'package:sheekhcali/features/home/presentation/widgets/date_header.dart';
import 'package:sheekhcali/features/navigation/presentation/app_drawer.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';
import 'package:sheekhcali/features/settings/presentation/settings_screen.dart';
import 'package:sheekhcali/features/splash/presentation/splash_screen.dart';

import '../support/test_app.dart';

void main() {
  group('Splash', () {
    testWidgets('shows the brand, then replaces itself with Home', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.splash);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Sheekh Calinuur'), findsOneWidget);
      expect(find.text('Islamic Digital Learning Platform'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('English: reference header, cards and tiles, LTR', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('THURSDAY'), findsOneWidget);
      expect(find.text('2 Jumada al-Thani 1448 AH'), findsOneWidget);
      expect(find.text('12 November 2026 CE'), findsOneWidget);
      expect(find.text('DHIKR OF THE DAY'), findsOneWidget);
      expect(find.text('Quran'), findsOneWidget);
      expect(find.text('Read, Listen, Tafsir & Explore'), findsOneWidget);
      expect(find.text('EXPLORE'), findsOneWidget);
      expect(find.text('Khatmah'), findsOneWidget);
      expect(find.text('Prayer Times & Qibla'), findsOneWidget);
      final ctx = tester.element(find.byType(DateHeader));
      expect(Directionality.of(ctx), TextDirection.ltr);
    });

    testWidgets(
      'dhikr content is a labelled placeholder, never invented text',
      (tester) async {
        await pumpApp(tester);
        expect(
          find.bySemanticsLabel(
            RegExp(r'^Placeholder: Verified Arabic dhikr text'),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Placeholder: Named translation')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Arabic: RTL, Arabic labels and Arabic-Indic digits', (
      tester,
    ) async {
      await pumpApp(tester, locale: 'ar');
      expect(find.text('الخميس'), findsOneWidget);
      expect(find.text('٢ جمادى الآخرة ١٤٤٨ هـ'), findsOneWidget);
      expect(find.text('ذكر اليوم'), findsOneWidget);
      expect(find.text('القرآن الكريم'), findsOneWidget);
      final ctx = tester.element(find.byType(DateHeader));
      expect(Directionality.of(ctx), TextDirection.rtl);
      // The menu button sits at the start edge, which is the right in RTL.
      final menu = tester.getCenter(find.byTooltip('فتح قائمة التنقل'));
      expect(menu.dx, greaterThan(384 / 2));
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('$locale: no overflow at 200% text scale', (tester) async {
        await pumpApp(tester, locale: locale, textScale: 2.0);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Quran card opens the reader', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Quran'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranReaderScreen), findsOneWidget);
    });

    testWidgets('tiles for unbuilt features open the honest placeholder', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Khatmah'));
      await tester.pumpAndSettle();
      expect(find.text('Coming in a later phase'), findsOneWidget);
    });
  });

  group('Drawer', () {
    testWidgets('English: header and every row from reference 02 plus DV-05', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(find.text('Sheekh Calinuur'), findsOneWidget);
      expect(find.text('Quran Tabsera'), findsNothing);
      for (final label in [
        'Home',
        'Library',
        "Sheikh's Lessons",
        'Tafsir',
        'Downloads',
        'Recent Page',
        'Index & Bookmark',
        'My Notes',
        'Itqan',
        'Statistics',
        'Recitation Correction',
      ]) {
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      final drawer = tester.getRect(find.byType(AppDrawer));
      expect(drawer.left, 0);
      expect(drawer.width, 289);
    });

    testWidgets('Arabic: opens from the right edge', (tester) async {
      await pumpApp(tester, locale: 'ar');
      await tester.tap(find.byTooltip('فتح قائمة التنقل'));
      await tester.pumpAndSettle();
      final drawer = tester.getRect(find.byType(AppDrawer));
      expect(drawer.right, 384);
      expect(find.text('الرئيسية'), findsOneWidget);
    });

    testWidgets('Settings row opens Settings, and the language switch works', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Settings'),
        100,
        scrollable: find.descendant(
          of: find.byType(AppDrawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('الإعدادات'), findsOneWidget);
      final ctx = tester.element(find.byType(SettingsScreen));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });

  // Verified-text reader behaviour lives in quran_reader_test.dart.
  group('Quran reader', () {
    testWidgets(
      'overflow menu has the four reference items and toggles light mode',
      (tester) async {
        await pumpApp(tester, location: AppRoutes.quran);
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();
        for (final label in [
          'Search',
          'Controls',
          'Go To Page',
          'Light mode',
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        await tester.tap(find.text('Light mode'));
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(QuranReaderScreen),
            matching: find.byType(Scaffold),
          ),
        );
        final ctx = tester.element(find.byWidget(scaffold));
        expect(Theme.of(ctx).scaffoldBackgroundColor, ReaderColors.pageLight);
      },
    );
  });
}
