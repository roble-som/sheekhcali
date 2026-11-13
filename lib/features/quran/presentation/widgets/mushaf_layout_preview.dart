import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/placeholder_box.dart';
import '../../../../l10n/app_localizations.dart';
import '../layout_preview.dart';

/// Renders [kLayoutPreviewLines] as hatched blocks in the measured mushaf
/// geometry: surah header 13.5 dp from each edge and 43 dp tall, a 281 dp text
/// column, and lines 29 dp apart. **No text is drawn.** The page always reads
/// right to left, whatever the interface language.
class MushafLayoutPreview extends StatelessWidget {
  const MushafLayoutPreview({
    super.key,
    required this.dark,
    required this.selectedAyah,
    required this.onAyahLongPress,
  });

  final bool dark;
  final int? selectedAyah;
  final ValueChanged<int> onAyahLongPress;

  static const double linePitch = 33.4;
  static const double textColumn = 281;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final column = textColumn.clamp(0, width - 40).toDouble();
    final marker = dark ? ReaderColors.ayahMarker : const Color(0xFF3E6A50);

    Widget segment(PreviewSegment s, double lineWidth) {
      final markerSpace = s.endsAyah ? 19.0 : 0.0;
      final blockWidth = (lineWidth * s.widthFactor - markerSpace).clamp(
        8.0,
        lineWidth,
      );
      final selected = s.ayah == selectedAyah;
      return Semantics(
        label: l10n.placeholderAyahSemantics(s.ayah),
        onLongPress: () => onAyahLongPress(s.ayah),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => onAyahLongPress(s.ayah),
          child: Container(
            height: linePitch - 2,
            margin: const EdgeInsets.symmetric(vertical: 1),
            color: selected ? ReaderColors.highlight : Colors.transparent,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                PlaceholderBox(
                  width: blockWidth,
                  height: 17,
                  onDark: dark || selected,
                  radius: 3,
                ),
                if (s.endsAyah)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: marker, width: 1.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.5),
          child: PlaceholderBox(
            height: AppSizes.surahHeaderHeight,
            onDark: dark,
            radius: 2,
            label: l10n.surahHeaderPlaceholder,
          ),
        ),
        const SizedBox(height: 7.5),
        for (final line in kLayoutPreviewLines)
          SizedBox(
            width: column * line.widthFactor,
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final s in line.segments)
                  segment(s, column * line.widthFactor),
              ],
            ),
          ),
      ],
    );
  }
}
