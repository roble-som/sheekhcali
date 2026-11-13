import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar/date_labels.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/home_components.dart';
import '../../../../l10n/app_localizations.dart';

/// Hamburger + weekday overline + Hijri date + Gregorian date (screenshot 01).
class DateHeader extends ConsumerWidget {
  const DateHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final styles = context.text;
    final labels = DateLabels.build(
      now: ref.watch(clockProvider)(),
      locale: locale,
      l10n: l10n,
      converter: ref.watch(hijriConverterProvider),
    );
    final weekday = styles.isArabic
        ? labels.weekday
        : labels.weekday.toUpperCase();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 15.5, 54, 0),
          child: Semantics(
            container: true,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: HomeColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(weekday, style: styles.weekday),
                  ],
                ),
                const SizedBox(height: 6.1),
                if (labels.hijri != null)
                  Text(
                    labels.hijri!,
                    style: styles.hijriDate,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 5.0),
                Text(
                  labels.gregorian,
                  style: styles.gregorianDate,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 16,
          top: 9.7,
          child: Builder(
            builder: (context) => HamburgerButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ],
    );
  }
}
