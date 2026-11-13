import 'package:flutter/foundation.dart';

/// A **layout-only** preview of a mushaf page, used while no verified Quran text
/// exists. It holds no text at all: just block widths, used to check the
/// reader's spacing, the ayah-selection highlight across line breaks (reference
/// 04), and the action sheet (reference 05). Every block renders hatched and
/// labelled "not Quran text".
@immutable
class PreviewSegment {
  const PreviewSegment({
    required this.widthFactor,
    required this.ayah,
    this.endsAyah = false,
  });

  /// Fraction of the line's width.
  final double widthFactor;

  /// Placeholder ayah index (1-based) inside this preview, for selection only.
  final int ayah;

  /// Draws an ayah-end marker after this segment.
  final bool endsAyah;
}

@immutable
class PreviewLine {
  const PreviewLine(this.widthFactor, this.segments);

  /// Width of the line as a fraction of the text column.
  final double widthFactor;

  /// Segments in reading order (right to left on screen).
  final List<PreviewSegment> segments;
}

/// Seven centred lines under a surah header. The line widths are measured from
/// the page geometry in references 03 and 04 (block proportions only; no text
/// is transcribed or stored).
const kLayoutPreviewLines = <PreviewLine>[
  PreviewLine(0.495, [PreviewSegment(widthFactor: 1, ayah: 1, endsAyah: true)]),
  PreviewLine(0.69, [PreviewSegment(widthFactor: 1, ayah: 2, endsAyah: true)]),
  PreviewLine(0.89, [
    PreviewSegment(widthFactor: 0.42, ayah: 3, endsAyah: true),
    PreviewSegment(widthFactor: 0.58, ayah: 4, endsAyah: true),
  ]),
  PreviewLine(0.93, [
    PreviewSegment(widthFactor: 0.78, ayah: 5, endsAyah: true),
    PreviewSegment(widthFactor: 0.22, ayah: 6),
  ]),
  PreviewLine(0.90, [
    PreviewSegment(widthFactor: 0.56, ayah: 6, endsAyah: true),
    PreviewSegment(widthFactor: 0.44, ayah: 7),
  ]),
  PreviewLine(0.665, [PreviewSegment(widthFactor: 1, ayah: 7)]),
  PreviewLine(0.395, [PreviewSegment(widthFactor: 1, ayah: 7, endsAyah: true)]),
];
