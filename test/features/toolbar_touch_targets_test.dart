import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/widgets/toolbar_action_strip.dart';

import '../support/test_app.dart';

/// Owner decision C-18: reader toolbar icons keep their 40 dp visual pitch but
/// get 48 × 48 dp touch targets; a tap in an overlap goes to the nearer icon.
void main() {
  const tooltipsEn = [
    'Open navigation menu',
    'Bookmark page',
    'Translation',
    'Index',
    'Auto-scroll',
    'More options',
  ];

  testWidgets('every reader toolbar button is at least 48 × 48 dp', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.quran);
    for (final t in tooltipsEn) {
      final size = tester.getSize(find.byTooltip(t));
      expect(size.width, greaterThanOrEqualTo(48), reason: t);
      expect(size.height, greaterThanOrEqualTo(48), reason: t);
    }
  });

  testWidgets('icons stay on the measured 40 dp pitch', (tester) async {
    await pumpApp(tester, location: AppRoutes.quran);
    final menu = tester.getCenter(find.byTooltip('Open navigation menu'));
    final more = tester.getCenter(find.byTooltip('More options'));
    final bookmark = tester.getCenter(find.byTooltip('Bookmark page'));
    expect(menu.dx, moreOrLessEquals(28.4, epsilon: 0.01));
    expect(more.dx, moreOrLessEquals(384 - 28.4, epsilon: 0.01));
    expect(more.dx - bookmark.dx, moreOrLessEquals(160, epsilon: 0.01));
  });

  testWidgets('a tap in an overlap goes to the nearer icon (LTR and RTL)', (
    tester,
  ) async {
    for (final locale in ['en', 'ar']) {
      await pumpApp(tester, locale: locale, location: AppRoutes.quran);
      final areas = find
          .byType(NearestHitArea)
          .evaluate()
          .map((e) => e.renderObject! as RenderNearestHitArea);
      double centreOf(RenderNearestHitArea a) =>
          a.localToGlobal(a.size.center(Offset.zero)).dx;
      final centres = areas.map(centreOf).toList()..sort();
      final y = tester.getCenter(find.byType(NearestHitArea).first).dy;

      // Probe every pair of neighbouring icons 40 dp apart, 1–3.9 dp either side
      // of their midpoint (inside both 48 dp targets).
      for (var i = 0; i + 1 < centres.length; i++) {
        if (centres[i + 1] - centres[i] > 41) continue; // not neighbours
        final mid = (centres[i] + centres[i + 1]) / 2;
        for (final d in [-3.9, -1.0, 1.0, 3.9]) {
          final x = mid + d;
          final expected = d < 0 ? centres[i] : centres[i + 1];
          final hit = tester
              .hitTestOnBinding(Offset(x, y))
              .path
              .map((e) => e.target)
              .whereType<RenderNearestHitArea>()
              .single;
          expect(
            centreOf(hit),
            moreOrLessEquals(expected, epsilon: 0.01),
            reason: '$locale: tap at $x should reach the icon at $expected',
          );
        }
      }
    }
  });
}
