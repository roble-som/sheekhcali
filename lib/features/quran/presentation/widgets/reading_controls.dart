import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/localized_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/presentation/app_drawer.dart';
import '../../../settings/application/preferences_controllers.dart';
import '../../application/reading_state.dart';
import '../../data/quran_metadata_repository.dart';
import '../../domain/quran_metadata.dart';

/// The reader's "Controls" sheet: layout (pages or whole surah), Quran text
/// size and the reading theme. All are saved.
Future<void> showReadingControls(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ReaderColors.surface,
    barrierColor: kReaderScrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (context) => const _ReadingControls(),
  );
}

class _ReadingControls extends ConsumerWidget {
  const _ReadingControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final size = ref.watch(quranFontSizeProvider);
    final dark = ref.watch(readerDarkProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.readingControls, style: styles.sheetItem),
            const SizedBox(height: 12),
            QuranLayoutControl(textStyle: styles.listTitle),
            const SizedBox(height: 8),
            QuranTextSizeControl(dark: false, textStyle: styles.listTitle),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.readerDarkPage, style: styles.listTitle),
              value: dark,
              onChanged: (v) =>
                  ref.read(readerDarkProvider.notifier).set(dark: v),
            ),
            Text(
              l10n.textSizeValue(
                localizeDigits(
                  '${size.round()}',
                  Localizations.localeOf(context),
                ),
              ),
              style: styles.listSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

/// "A− [sample] A+" for the Quran text size, with a reset. Used in the
/// reader's controls sheet and in Settings.
class QuranTextSizeControl extends ConsumerWidget {
  const QuranTextSizeControl({
    super.key,
    required this.dark,
    required this.textStyle,
  });

  final bool dark;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final size = ref.watch(quranFontSizeProvider);
    final notifier = ref.read(quranFontSizeProvider.notifier);
    return Row(
      children: [
        Expanded(child: Text(l10n.quranTextSize, style: textStyle)),
        IconButton(
          key: const ValueKey('text-size-smaller'),
          tooltip: l10n.textSmaller,
          onPressed: size <= QuranFontSizeController.min
              ? null
              : () => notifier.set(size - QuranFontSizeController.step),
          icon: const Icon(Icons.text_decrease),
        ),
        IconButton(
          key: const ValueKey('text-size-larger'),
          tooltip: l10n.textLarger,
          onPressed: size >= QuranFontSizeController.max
              ? null
              : () => notifier.set(size + QuranFontSizeController.step),
          icon: const Icon(Icons.text_increase),
        ),
        TextButton(
          onPressed: size == QuranFontSizeController.standard
              ? null
              : () => notifier.set(QuranFontSizeController.standard),
          child: Text(l10n.textSizeReset),
        ),
      ],
    );
  }
}

/// Pages (Madinah Mushaf page boundaries) or one whole surah. Pages are
/// offered only when verified page data is installed.
class QuranLayoutControl extends ConsumerWidget {
  const QuranLayoutControl({super.key, required this.textStyle});

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final layout = ref.watch(quranLayoutProvider);
    final meta = ref.watch(quranMetadataProvider).value;
    final hasPages = meta is QuranMetadataAvailable && meta.metadata.hasPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.readingLayout, style: textStyle),
        const SizedBox(height: 8),
        SegmentedButton<QuranLayout>(
          key: const ValueKey('layout-switch'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: QuranLayout.pages,
              enabled: hasPages,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.layoutPages),
            ),
            ButtonSegment(
              value: QuranLayout.surah,
              icon: const Icon(Icons.notes),
              label: Text(l10n.layoutSurah),
            ),
          ],
          selected: {hasPages ? layout : QuranLayout.surah},
          onSelectionChanged: (s) =>
              ref.read(quranLayoutProvider.notifier).set(s.first),
        ),
        if (hasPages && layout == QuranLayout.pages) ...[
          const SizedBox(height: 6),
          Text(l10n.layoutPagesNote, style: context.text.listSubtitle),
        ],
      ],
    );
  }
}
