import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/library/presentation/book_details_screen.dart';
import 'package:sheekhcali/features/library/presentation/library_screen.dart';

import '../support/test_app.dart';

const _preview = {'debug.designPreview': true};

void main() {
  group('shipped state (nothing published)', () {
    testWidgets('Home "Library" tile opens the honest empty state', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.text('No books yet'), findsOneWidget);
      expect(find.text('Design preview data · not real books'), findsNothing);
      expect(find.byType(BookRow), findsNothing);
    });

    testWidgets('unknown book id says the book is not available', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.book('nope'));
      expect(find.byType(BookDetailsScreen), findsOneWidget);
      expect(find.text("This book isn't available."), findsOneWidget);
    });
  });

  group('design preview data (debug only)', () {
    testWidgets('banner, shelf and labelled preview rows', (tester) async {
      await pumpApp(tester, location: AppRoutes.library, extraPrefs: _preview);
      expect(find.text('Design preview data · not real books'), findsOneWidget);
      expect(find.text("SHEIKH CALINUUR'S BOOKS"), findsOneWidget);
      expect(find.text('ALL BOOKS'), findsOneWidget);
      expect(find.text('Preview'), findsWidgets);
    });

    testWidgets('category filter and search narrow the list', (tester) async {
      await pumpApp(tester, location: AppRoutes.library, extraPrefs: _preview);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Hadith'));
      await tester.pumpAndSettle();
      expect(find.byType(BookRow), findsOneWidget);
      expect(find.text("SHEIKH CALINUUR'S BOOKS"), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'preview book 6');
      await tester.pumpAndSettle();
      expect(find.byType(BookRow), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No books match your search'), findsOneWidget);
    });

    testWidgets('book details: Not recorded fields, contents, honest actions', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: AppRoutes.book('preview-1'),
        extraPrefs: _preview,
      );
      // Shown as the heading and on the typographic cover.
      expect(find.text('كتاب معاينة ١'), findsNWidgets(2));
      expect(find.text('Preview book 1'), findsOneWidget);
      // Author, edition, publisher and pages are not recorded.
      expect(find.textContaining('Not recorded'), findsNWidgets(4));
      expect(find.text('Volume 1'), findsOneWidget);
      expect(find.text('2 lessons'), findsOneWidget);
      expect(find.text('No lessons'), findsWidgets);
      await tester.tap(find.text('Read'));
      await tester.pump();
      expect(find.textContaining('later phase'), findsOneWidget);
    });

    testWidgets('tapping a row opens its details', (tester) async {
      await pumpApp(tester, location: AppRoutes.library, extraPrefs: _preview);
      await tester.enterText(find.byType(TextField), 'preview book 6');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(BookRow, 'Preview book 6'));
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailsScreen), findsOneWidget);
      expect(
        find.textContaining('English', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Arabic: RTL with Arabic labels and digits', (tester) async {
      await pumpApp(
        tester,
        locale: 'ar',
        location: AppRoutes.book('preview-1'),
        extraPrefs: _preview,
      );
      final ctx = tester.element(find.byType(BookDetailsScreen));
      expect(Directionality.of(ctx), TextDirection.rtl);
      expect(find.text('المجلد ١'), findsOneWidget);
      expect(find.text('درسان'), findsOneWidget);
      expect(find.textContaining('غير مسجل'), findsWidgets);
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('$locale: no overflow at 200% text', (tester) async {
        await pumpApp(
          tester,
          locale: locale,
          location: AppRoutes.library,
          extraPrefs: _preview,
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BookRow).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
