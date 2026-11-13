import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A clearly marked placeholder for a missing asset or for content that isn't
/// verified yet: diagonal hatching, a dashed border and a visible label. Screen
/// readers announce it as a placeholder.
///
/// Rule (Phase 1 approval §6): every missing logo, photo, illustration or
/// religious text is shown with this widget, never with invented content.
class PlaceholderBox extends StatelessWidget {
  const PlaceholderBox({
    super.key,
    this.label,
    this.onDark = false,
    this.circle = false,
    this.width,
    this.height,
    this.radius = AppRadii.placeholder,
    this.showBorder = true,
    this.labelAlignment = Alignment.center,
    this.labelStyle,
    this.padding = const EdgeInsets.all(6),
  });

  final String? label;
  final bool onDark;
  final bool circle;
  final double? width;
  final double? height;
  final double radius;
  final bool showBorder;
  final AlignmentGeometry labelAlignment;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = onDark ? const Color(0xB3FFFFFF) : const Color(0xFF5A5D5A);
    final hatch = onDark ? const Color(0x14FFFFFF) : const Color(0x12000000);
    final border = onDark ? const Color(0x59FFFFFF) : const Color(0x47000000);
    final text = label;
    return Semantics(
      label: l10n.placeholderSemantics(text ?? ''),
      excludeSemantics: true,
      child: CustomPaint(
        painter: _HatchPainter(
          hatch: hatch,
          border: showBorder ? border : null,
          circle: circle,
          radius: radius,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: text == null
              ? null
              : Padding(
                  padding: padding,
                  child: Align(
                    alignment: labelAlignment,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: (labelStyle ?? context.text.placeholderLabel)
                          .copyWith(color: ink),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({
    required this.hatch,
    required this.border,
    required this.circle,
    required this.radius,
  });

  final Color hatch;
  final Color? border;
  final bool circle;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = circle
        ? (Path()..addOval(rect))
        : (Path()
            ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))));
    canvas.save();
    canvas.clipPath(shape);
    final paint = Paint()
      ..color = hatch
      ..strokeWidth = 4.5;
    const step = 9.0;
    final extent = size.width + size.height;
    for (double d = -size.height; d < extent; d += step) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        paint,
      );
    }
    canvas.restore();

    final b = border;
    if (b == null) return;
    final stroke = Paint()
      ..color = b
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in shape.computeMetrics()) {
      const dash = 4.0;
      const gap = 3.0;
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) =>
      old.hatch != hatch ||
      old.border != border ||
      old.circle != circle ||
      old.radius != radius;
}
