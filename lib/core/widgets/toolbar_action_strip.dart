import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_spacing.dart';

/// One action in a [ToolbarActionStrip].
@immutable
class ToolbarAction {
  const ToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 21,
    this.color,
    this.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? color;
  final Key? key;
}

/// Toolbar icons laid out at the reference's visual pitch (40 dp in
/// screenshot 03), each with a **48 × 48 dp touch target** centred on its icon
/// (owner decision C-18).
///
/// With a 40 dp pitch, neighbouring 48 dp targets must overlap by 8 dp. A tap
/// inside an overlap goes to the nearer icon: each target ignores the 4 dp strip
/// on any side that touches a neighbour, which is exactly the half of the
/// overlap that is closer to that neighbour.
///
/// The strip's own box includes the outer overhang ((48 − pitch) / 2 on each
/// end) so the outer targets are hittable too. Callers place it so that the
/// icons land on their measured positions (see [ReaderAppBar]).
class ToolbarActionStrip extends StatelessWidget {
  const ToolbarActionStrip({
    super.key,
    required this.actions,
    this.pitch = 40,
    this.defaultColor = Colors.white,
  });

  final List<ToolbarAction> actions;
  final double pitch;
  final Color defaultColor;

  static const double target = AppSizes.touchMin;

  @override
  Widget build(BuildContext context) {
    final overhang = (target - pitch) / 2;
    final n = actions.length;
    return SizedBox(
      width: pitch * n + overhang * 2,
      height: AppSizes.appBar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            PositionedDirectional(
              start: i * pitch,
              top: (AppSizes.appBar - target) / 2,
              width: target,
              height: target,
              child: NearestHitArea(
                startExclusion: i > 0 ? overhang : 0,
                endExclusion: i < n - 1 ? overhang : 0,
                child: IconButton(
                  key: actions[i].key,
                  onPressed: actions[i].onPressed,
                  tooltip: actions[i].tooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: target,
                    height: target,
                  ),
                  icon: Icon(
                    actions[i].icon,
                    size: actions[i].iconSize,
                    color: actions[i].color ?? defaultColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ignores hits within [startExclusion] / [endExclusion] logical pixels of its
/// start / end edges, so overlapping touch targets split their overlap fairly.
/// Its size, and so its semantics rect, is unchanged.
class NearestHitArea extends SingleChildRenderObjectWidget {
  const NearestHitArea({
    super.key,
    required this.startExclusion,
    required this.endExclusion,
    super.child,
  });

  final double startExclusion;
  final double endExclusion;

  @override
  RenderNearestHitArea createRenderObject(BuildContext context) =>
      RenderNearestHitArea(
        startExclusion: startExclusion,
        endExclusion: endExclusion,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderNearestHitArea renderObject,
  ) {
    renderObject
      ..startExclusion = startExclusion
      ..endExclusion = endExclusion
      ..textDirection = Directionality.of(context);
  }
}

class RenderNearestHitArea extends RenderProxyBox {
  RenderNearestHitArea({
    required this.startExclusion,
    required this.endExclusion,
    required this.textDirection,
  });

  double startExclusion;
  double endExclusion;
  TextDirection textDirection;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final rtl = textDirection == TextDirection.rtl;
    final left = rtl ? endExclusion : startExclusion;
    final right = rtl ? startExclusion : endExclusion;
    if (position.dx < left || position.dx > size.width - right) return false;
    return super.hitTest(result, position: position);
  }
}
