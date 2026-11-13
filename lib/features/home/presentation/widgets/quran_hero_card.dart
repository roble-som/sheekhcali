import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/home_components.dart';
import '../../../../l10n/app_localizations.dart';

/// The green Quran hero card (screenshot 01). Its gradient runs from the start
/// edge to the end edge, so the darker end stays at the end in RTL.
class QuranHeroCard extends StatelessWidget {
  const QuranHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      button: true,
      label: '${l10n.quranCardTitle}. ${l10n.quranCardSubtitle}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.quranCardHeight),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            stops: [0, 0.75],
            colors: [HomeColors.cardGradStart, HomeColors.cardGradEnd],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.cardPadding,
                14,
                AppSpacing.cardPadding,
                14,
              ),
              child: Row(
                children: [
                  const LogoMedallion(size: AppSizes.medallion, onDark: true),
                  const SizedBox(width: 19.7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.quranCardTitle, style: styles.heroTitle),
                        const SizedBox(height: 4),
                        Text(
                          l10n.quranCardSubtitle,
                          style: styles.heroSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ChevronChip(
                    size: AppSizes.chevronChip,
                    background: HomeColors.greenChip,
                    border: Color(0x33FFFFFF),
                    iconColor: Colors.white,
                    iconSize: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
