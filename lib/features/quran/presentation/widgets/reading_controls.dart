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

/// The reader's "Controls" sheet: Quran text size and the reading theme.
/// Both are saved and also available in Settings.
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
