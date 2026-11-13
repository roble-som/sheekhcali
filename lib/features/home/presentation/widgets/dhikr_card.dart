import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/placeholder_box.dart';
import '../../../../l10n/app_localizations.dart';

/// "Dhikr of the Day" card (screenshot 01).
///
/// No verified dhikr source exists yet (P-12), so the Arabic text, the
/// translation and the mosque photo are clearly marked placeholders. The
/// reference line is the approved addition DV-03: no dhikr is ever shown
/// without its source.
///
/// At normal text sizes the card keeps the measured 277 dp height. Above
/// 1.15× text scale it grows with its content instead of clipping
/// (WCAG 1.4.4, DESIGN_SYSTEM_SPECIFICATION §10).
class DhikrCard extends StatelessWidget {
  const DhikrCard({super.key});

  static const _largeTextThreshold = 1.15;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final large =
        MediaQuery.textScalerOf(context).scale(10) / 10 > _largeTextThreshold;
    final label = styles.isArabic
        ? l10n.dhikrOfTheDay
        : l10n.dhikrOfTheDay.toUpperCase();

    final header = Semantics(
      header: true,
      child: Row(
        children: [
          Container(width: 25, height: 2, color: HomeColors.goldRule),
          const SizedBox(width: 13.5),
          Flexible(child: Text(label, style: styles.dhikrLabel)),
        ],
      ),
    );
    final divider = const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Divider(height: 1, thickness: 1, color: HomeColors.dhikrDivider),
    );
    final reference = Text(
      l10n.placeholderDhikrReference,
      maxLines: large ? null : 1,
      overflow: large ? null : TextOverflow.ellipsis,
      style: styles.placeholderLabel.copyWith(
        color: const Color(0xBFFFFFFF),
        fontSize: 11.5,
      ),
    );
    PlaceholderBox box(String text, {double? height}) => PlaceholderBox(
      onDark: true,
      height: height,
      label: text,
      padding: const EdgeInsets.all(10),
    );

    final Widget content;
    if (large) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: 10),
          Text(
            l10n.placeholderPhoto,
            style: styles.placeholderLabel.copyWith(
              color: const Color(0xB3FFFFFF),
            ),
          ),
          const SizedBox(height: 10),
          box(l10n.placeholderDhikrArabic),
          divider,
          box(l10n.placeholderDhikrTranslation),
          const SizedBox(height: 9),
          reference,
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Expanded(flex: 80, child: box(l10n.placeholderDhikrArabic)),
          divider,
          Expanded(flex: 72, child: box(l10n.placeholderDhikrTranslation)),
          const SizedBox(height: 9),
          reference,
        ],
      );
    }

    return Container(
      height: large ? null : AppSizes.dhikrCardHeight,
      constraints: const BoxConstraints(minHeight: AppSizes.dhikrCardHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HomeColors.dhikrTop, HomeColors.dhikrBottom],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // The mosque photo in the reference isn't supplied (rights needed).
          Positioned.fill(
            child: PlaceholderBox(
              onDark: true,
              showBorder: false,
              radius: AppRadii.card,
              label: large ? null : l10n.placeholderPhoto,
              labelAlignment: AlignmentDirectional.topEnd,
              labelStyle: styles.placeholderLabel.copyWith(fontSize: 9.5),
              padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 14, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.cardPadding,
              22,
              AppSpacing.cardPadding,
              18,
            ),
            child: content,
          ),
        ],
      ),
    );
  }
}
