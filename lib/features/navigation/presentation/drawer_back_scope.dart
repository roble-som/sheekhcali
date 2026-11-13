import 'package:flutter/material.dart';

/// Makes the system back gesture close an open drawer instead of leaving the
/// app (DESIGN_SYSTEM_SPECIFICATION §7).
///
/// Why this exists: on Android 16 (target SDK 36) predictive back is on by
/// default, and Android only sends back to Flutter when the framework has
/// reported that it can handle it. Scaffold's drawer registers only a local
/// history entry, which doesn't send that report, so a back press with the
/// drawer open closed the whole app. This was found on the emulator during
/// Phase 1 validation. A [PopScope] that blocks pops while the drawer is open
/// does send the report, and its callback closes the drawer.
class DrawerBackScope extends StatefulWidget {
  const DrawerBackScope({
    super.key,
    required this.scaffoldKey,
    required this.builder,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Builds the Scaffold. Pass `onDrawerChanged` to `Scaffold.onDrawerChanged`.
  final Widget Function(
    BuildContext context,
    ValueChanged<bool> onDrawerChanged,
  )
  builder;

  @override
  State<DrawerBackScope> createState() => _DrawerBackScopeState();
}

class _DrawerBackScopeState extends State<DrawerBackScope> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _drawerOpen) {
          widget.scaffoldKey.currentState?.closeDrawer();
        }
      },
      child: widget.builder(context, (open) {
        if (open != _drawerOpen) setState(() => _drawerOpen = open);
      }),
    );
  }
}
