import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/navigation/presentation/app_drawer.dart';
import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/presentation/quran_index_screen.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';

import '../support/synthetic_quran_metadata.dart';
import '../support/test_app.dart';

void main() {
  final synthetic = [
    quranMetadataRepositoryProvider.overrideWithValue(
      const SyntheticQuranMetadataRepository(),
    ),
  ];

  group('shipped state: no verified metadata', () {
    testWidgets('reader index button opens the index with the honest notice', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.quran);
      await tester.tap(find.byTooltip('Index'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranIndexScreen), findsOneWidget);
      expect(
        find.text('Surah and juz index not available yet'),
        findsOneWidget,
      );
      expect(find.text('Layout preview · not real data'), findsOneWidget);
      // No surah rows are listed at all.
      expect(find.bySemanticsLabel(RegExp(r'^Surah \d')), findsNothing);
    });

    testWidgets('drawer "Index & Bookmark" opens the index', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Index & Bookmark'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuranIndexScreen), findsOneWidget);
    });

    testWidgets('Arabic: tabs and notice in Arabic, RTL', (tester) async {
      await pumpApp(tester, locale: 'ar', location: AppRoutes.quranIndex);
      expect(find.text('السور'), findsOneWidget);
      expect(find.text('الأجزاء'), findsOneWidget);
      expect(find.text('فهرس السور والأجزاء غير متاح بعد'), findsOneWidget);
      final ctx = tester.element(find.byType(QuranIndexScreen));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });

  group('with verified metadata (synthetic test fixture)', () {
    testWidgets('lists surahs with details and opens the reader', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: AppRoutes.quranIndex,
        overrides: synthetic,
      );
      expect(find.text('Ikhtibar-Awwal'), findsOneWidget);
      expect(
        find.text('Synthetic chapter one · Makki · 3 ayahs'),
        findsOneWidget,
      );
      expect(
        find.text('Synthetic chapter two · Madani · 1 ayah'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ikhtibar-Thani'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranReaderScreen), findsOneWidget);
    });

    testWidgets(
      'search by number, hyphen-less name, and Arabic without harakat',
      (tester) async {
        await pumpApp(
          tester,
          location: AppRoutes.quranIndex,
          overrides: synthetic,
        );
        final field = find.byType(TextField).first;

        await tester.enterText(field, '12');
        await tester.pump();
        expect(find.text('Ikhtibar-Akhir'), findsOneWidget);
        expect(find.text('Ikhtibar-Awwal'), findsNothing);

        await tester.enterText(field, 'ikhtibar thani');
        await tester.pump();
        expect(find.text('Ikhtibar-Thani'), findsOneWidget);
        expect(find.text('Ikhtibar-Awwal'), findsNothing);

        // The stored name has harakat; the query has none, and uses plain alef.
        await tester.enterText(field, 'اختبار اول');
        await tester.pump();
        expect(find.text('Ikhtibar-Awwal'), findsOneWidget);

        await tester.enterText(field, 'zzz');
        await tester.pump();
        expect(find.text('No matches'), findsOneWidget);
      },
    );

    testWidgets('juz tab lists starts', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.quranIndex,
        overrides: synthetic,
      );
      await tester.tap(find.text('Juz'));
      await tester.pumpAndSettle();
      expect(find.text('Juz 2'), findsOneWidget);
      expect(find.text('Starts at Ikhtibar-Thani 2:1'), findsOneWidget);
    });

    testWidgets('Arabic: Arabic names, Arabic plurals and digits', (
      tester,
    ) async {
      await pumpApp(
        tester,
        locale: 'ar',
        location: AppRoutes.quranIndex,
        overrides: synthetic,
      );
      expect(find.text('اِخْتِبَارٌ أَوَّل'), findsOneWidget);
      expect(find.text('مكية · ٣ آيات'), findsOneWidget);
      expect(find.text('مدنية · آية واحدة'), findsOneWidget);
      expect(find.text('مكية · ١١ آية'), findsOneWidget);
      expect(find.text('Ikhtibar-Awwal'), findsNothing);
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('$locale: no overflow at 200% text', (tester) async {
        await pumpApp(
          tester,
          locale: locale,
          location: AppRoutes.quranIndex,
          overrides: synthetic,
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
