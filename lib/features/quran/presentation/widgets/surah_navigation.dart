import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/localized_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/quran_metadata_repository.dart';
import '../../domain/quran_metadata.dart';

/// "Previous surah" / "Next surah" at the end of the text, with the
/// neighbours' names from the verified metadata.
class SurahNavigation extends ConsumerWidget {
  const SurahNavigation({super.key, required this.surah, required this.dark});

  final int surah;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final locale = Localizations.localeOf(context);
    final arabicUi = locale.languageCode == 'ar';
    final meta = ref.watch(quranMetadataProvider).value;
    final metadata = meta is QuranMetadataAvailable ? meta.metadata : null;
    final ink = dark ? Colors.white : ReaderColors.text;

    String name(int n) {
      final s = metadata?.surah(n);
      if (s == null) return localizeDigits('$n', locale);
      return arabicUi ? s.nameArabic : s.nameTransliterated;
    }

    Widget button({
      required int target,
      required String label,
      required IconData icon,
      required bool next,
    }) {
      final text = Column(
        crossAxisAlignment: next
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: styles.listSubtitle.copyWith(
              color: ink.withValues(alpha: 0.7),
            ),
          ),
          Text(
            name(target),
            style: styles.listTitle.copyWith(color: ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
      return Expanded(
        child: InkWell(
          key: ValueKey(next ? 'next-surah' : 'previous-surah'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.pushReplacement(AppRoutes.quranAt(target)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: next
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!next) Icon(icon, color: ink),
                  if (!next) const SizedBox(width: 6),
                  Flexible(child: text),
                  if (next) const SizedBox(width: 6),
                  if (next) Icon(icon, color: ink),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (surah > 1)
          button(
            target: surah - 1,
            label: l10n.previousSurah,
            icon: Icons.chevron_left,
            next: false,
          )
        else
          const Spacer(),
        const SizedBox(width: 8),
        if (surah < 114)
          button(
            target: surah + 1,
            label: l10n.nextSurah,
            icon: Icons.chevron_right,
            next: true,
          )
        else
          const Spacer(),
      ],
    );
  }
}
