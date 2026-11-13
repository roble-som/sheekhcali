import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/home/presentation/home_screen.dart';
import 'package:sheekhcali/features/navigation/presentation/app_drawer.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';

import '../support/test_app.dart';

/// DESIGN_SYSTEM_SPECIFICATION §7: system back closes the drawer before it
/// leaves the screen. On Android 16 (predictive back) this only works if the
/// framework reports `setFrameworkHandlesBack(true)` while the drawer is open.
/// A regression of this closed the app on the emulator.
void main() {
  late List<bool> handlesBack;

  setUp(() {
    handlesBack = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            handlesBack.add(call.arguments as bool);
          }
          return null;
        });
  });

  for (final (name, location, screen) in [
    ('Home', AppRoutes.home, HomeScreen),
    ('Quran reader', AppRoutes.quran, QuranReaderScreen),
  ]) {
    testWidgets('$name: open drawer tells the platform it handles back', (
      tester,
    ) async {
      // Flutter only reports back handling once the app has a lifecycle state,
      // as on a real device.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpApp(tester, location: location);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(handlesBack, isNotEmpty);
      expect(handlesBack.last, isTrue);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.byType(AppDrawer), findsNothing);
      expect(find.byType(screen), findsOneWidget);
    });
  }
}
