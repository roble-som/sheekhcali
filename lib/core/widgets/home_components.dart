import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'placeholder_box.dart';

/// The Home hamburger from screenshot 01: three rounded lines, with the bottom
/// line shorter. The short line sits at the start edge, so it mirrors in RTL.
class HamburgerButton extends StatelessWidget {
  const HamburgerButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context).openMenu,
      constraints: const BoxConstraints.tightFor(
        width: AppSizes.touchMin,
        height: AppSizes.touchMin,
      ),
      padding: EdgeInsets.zero,
      icon: CustomPaint(
        size: const Size(23, 18),
        painter: _HamburgerPainter(
          color: HomeColors.hamburger,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _HamburgerPainter extends CustomPainter {
  _HamburgerPainter({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const inset = 1.1;
    final w = size.width - inset * 2;
    final ys = [inset, size.height / 2, size.height - inset];
    final lengths = [w, w, w * 0.6];
    for (var i = 0; i < 3; i++) {
      final start = rtl ? size.width - inset - lengths[i] : inset;
      canvas.drawLine(
        Offset(start, ys[i]),
        Offset(start + lengths[i], ys[i]),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HamburgerPainter old) =>
      old.color != color || old.rtl != rtl;
}

/// The round logo medallion. The real logo isn't supplied yet (P-02), so this
/// draws a clearly marked placeholder inside a neutral gold ring.
class LogoMedallion extends StatelessWidget {
  const LogoMedallion({super.key, required this.size, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.06;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9C766), Color(0xFFB98D2C)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onDark ? const Color(0xFF2B5039) : const Color(0xFFF1F1EE),
        ),
        child: PlaceholderBox(
          circle: true,
          onDark: onDark,
          showBorder: false,
          label: size >= 40
              ? AppLocalizations.of(context).placeholderLogo
              : null,
          labelStyle: context.text.placeholderLabel.copyWith(
            fontSize: size >= 56 ? 11 : 9,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// An uppercase overline with a hairline rule running to the end edge
/// ("EXPLORE" in screenshot 01). Arabic has no case, so no transform is
/// applied there.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  static const double _gap = 18;
  static const double _minRule = 24;

  @override
  Widget build(BuildContext context) {
    final styles = context.text;
    final text = styles.isArabic ? label : label.toUpperCase();
    final style = styles.sectionLabel;
    return Semantics(
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If the label (at the current text scale) leaves room for the rule,
          // use the reference layout. Otherwise (large text, long labels) let
          // the label wrap on its own so nothing is clipped.
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final fits = painter.width + _gap + _minRule <= constraints.maxWidth;
          painter.dispose();
          if (!fits) return Text(text, style: style);
          return Row(
            children: [
              Text(text, style: style),
              const SizedBox(width: _gap),
              const Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: HomeColors.sectionRule,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The circular chevron used on cards and tiles. `Icons.chevron_right` mirrors
/// automatically in RTL.
class ChevronChip extends StatelessWidget {
  const ChevronChip({
    super.key,
    required this.size,
    required this.background,
    required this.iconColor,
    this.border,
    this.iconSize = 16,
  });

  final double size;
  final Color background;
  final Color iconColor;
  final Color? border;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border!, width: 1),
        ),
        child: Icon(Icons.chevron_right, size: iconSize, color: iconColor),
      ),
    );
  }
}

enum FeatureTileTone { cool, warm }

/// A feature tile from the EXPLORE grid (screenshot 01). The whole tile is the
/// touch target; the chevron chip is decorative.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final FeatureTileTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cool = tone == FeatureTileTone.cool;
    final styles = context.text;
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tileMinHeight),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: HomeColors.tileBorder),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: cool
                ? const [Colors.white, HomeColors.tileCoolBottom]
                : const [Colors.white, HomeColors.tileWarmBottom],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 13,
                  end: 12,
                  child: ChevronChip(
                    size: AppSizes.tileChip,
                    background: cool
                        ? HomeColors.tileCoolChip
                        : HomeColors.tileWarmChip,
                    border: cool
                        ? HomeColors.tileCoolChipBorder
                        : HomeColors.tileWarmChipBorder,
                    iconColor: cool
                        ? HomeColors.tileCoolChipIcon
                        : HomeColors.tileWarmChipIcon,
                    iconSize: 14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.tilePadding,
                    24,
                    AppSpacing.tilePadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlaceholderBox(
                        width: 62,
                        height: 38,
                        label: AppLocalizations.of(context)
                            .placeholderIllustration,
                        labelStyle: styles.placeholderLabel.copyWith(
                          fontSize: 9,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 14),
                      Text(title, style: styles.tileTitle),
                      const SizedBox(height: 6),
                      Text(subtitle, style: styles.tileSubtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows an honest "not available yet" message.
void showUnavailable(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
