import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/presentation/app_drawer.dart';

enum AyahAction {
  playToEnd,
  playTafsir,
  playRecitationAndTafsir,
  addNote,
  addItqan,
  tafsir,
  bookmark,
  copy,
  share,
}

/// The ayah action sheet from screenshot 05: a white sheet with a 16 dp top
/// radius, a drag handle, 52 dp rows, icons centred at 32 dp, labels starting
/// at 60.4 dp, and a divider before Copy and Share.
Future<AyahAction?> showAyahActionSheet(BuildContext context) {
  return showModalBottomSheet<AyahAction>(
    context: context,
    backgroundColor: ReaderColors.surface,
    barrierColor: kReaderScrim,
    showDragHandle: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (context) => const _AyahActionSheet(),
  );
}

class _AyahActionSheet extends StatelessWidget {
  const _AyahActionSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget row(
      AyahAction action,
      IconData icon,
      String primary, [
      String? secondary,
    ]) {
      return InkWell(
        onTap: () => Navigator.of(context).pop(action),
        child: SizedBox(
          height: AppSizes.sheetRow,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(icon, size: 24, color: ReaderColors.text),
              const SizedBox(width: 16.4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: primary,
                    style: styles.sheetItem,
                    children: [
                      if (secondary != null)
                        TextSpan(
                          text: ' $secondary',
                          style: styles.sheetItemSecondary,
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom > 0 ? 0 : 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6.4),
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: ReaderColors.handle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4.6),
            row(
              AyahAction.playToEnd,
              Icons.play_arrow,
              l10n.ayahPlay,
              l10n.ayahToEndOfSura,
            ),
            row(
              AyahAction.playTafsir,
              Icons.record_voice_over,
              l10n.ayahPlay,
              l10n.ayahTafsir,
            ),
            row(
              AyahAction.playRecitationAndTafsir,
              Icons.playlist_play,
              l10n.ayahPlay,
              l10n.ayahRecitationPlusTafsir,
            ),
            row(AyahAction.addNote, Icons.note_alt_outlined, l10n.ayahAddNote),
            row(
              AyahAction.addItqan,
              Icons.workspace_premium_outlined,
              l10n.ayahAddItqan,
            ),
            row(AyahAction.tafsir, Icons.menu_book, l10n.ayahTafsir),
            row(AyahAction.bookmark, Icons.bookmark_border, l10n.ayahBookmark),
            const Divider(height: 1, thickness: 1, color: ReaderColors.divider),
            row(AyahAction.copy, Icons.description_outlined, l10n.ayahCopy),
            row(AyahAction.share, Icons.ios_share, l10n.ayahShare),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
