import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/localized_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/reading_state.dart';
import '../../domain/quran_metadata.dart';

/// The user's ayah bookmarks (newest first): tap to open the ayah, or remove.
class BookmarksList extends ConsumerWidget {
  const BookmarksList({super.key, required this.metadata});

  /// For surah names; null shows numbers only.
  final QuranMetadata? metadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final locale = Localizations.localeOf(context);
    final arabicUi = locale.languageCode == 'ar';
    final bookmarks = ref.watch(bookmarksProvider);

    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_border,
                size: 48,
                color: ReaderColors.icon,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bookmarksEmptyTitle,
                style: styles.listTitle.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.bookmarksEmptyBody,
                style: styles.listSubtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, i) {
        final b = bookmarks[i];
        final surah = metadata?.surah(b.surah);
        final name = surah == null
            ? localizeDigits('${b.surah}', locale)
            : (arabicUi ? surah.nameArabic : surah.nameTransliterated);
        final reference = localizeDigits('${b.surah}:${b.ayah}', locale);
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ReaderColors.divider)),
          ),
          child: ListTile(
            key: ValueKey('bookmark-${b.encode()}'),
            minVerticalPadding: 12,
            leading: const Icon(Icons.bookmark, color: ReaderColors.icon),
            title: Text(name, style: styles.listTitle),
            subtitle: Text(
              l10n.bookmarkAyahLine(reference),
              style: styles.listSubtitle,
            ),
            onTap: () => context.push(AppRoutes.quranAt(b.surah, b.ayah)),
            trailing: IconButton(
              tooltip: l10n.ayahRemoveBookmark,
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(bookmarksProvider.notifier).toggle(b),
            ),
          ),
        );
      },
    );
  }
}
