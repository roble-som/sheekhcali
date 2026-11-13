import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/domain/app_destination.dart';

/// An honest destination for sections that aren't built yet. It never shows
/// sample or invented content.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.destination});

  final AppDestination? destination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final title = destination?.label(l10n) ?? l10n.comingSoonTitle;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: HomeColors.bg,
        appBar: AppBar(
          backgroundColor: HomeColors.bg,
          foregroundColor: HomeColors.green900,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(title, style: styles.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  destination?.icon ?? Icons.hourglass_empty,
                  size: 44,
                  color: HomeColors.greenChip,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.comingSoonTitle,
                  style: styles.title.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.comingSoonBody,
                  style: styles.body.copyWith(color: HomeColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
