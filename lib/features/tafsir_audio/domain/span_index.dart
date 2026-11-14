import 'package:flutter/foundation.dart';

import 'alignment.dart';
import 'candidates.dart';

/// Why a span index has no usable spans. Shown to the user as a short note.
enum SyncUnavailableReason {
  /// The alignment file has no verified spans yet (review pending, C-27).
  noVerifiedSpans,

  /// The alignment was made for a different recording (checksum differs).
  recordingMismatch,

  /// The alignment failed validation.
  invalid,
}

/// Maps playback positions to verified spans, and ayahs to their spans.
///
/// Built once per (alignment, recording, text). Only spans that are
/// **verified**, structurally valid, bound to the loaded recording's SHA-256,
/// and whose target ayah texts still have the hashes recorded at alignment
/// time are included. Everything else highlights nothing (never a guess).
@immutable
class SpanIndex {
  const SpanIndex._(this._spans, this.unavailableReason, this.excludedStale);

  /// [currentAyahSha256]: ayah number → hash of the text now on screen.
  factory SpanIndex.build({
    required TafsirAlignment alignment,
    required String loadedRecordingSha256,
    required Map<int, String> currentAyahSha256,
  }) {
    if (alignment.recordingSha256 != loadedRecordingSha256) {
      return SpanIndex._(const [], SyncUnavailableReason.recordingMismatch, 0);
    }
    if (validateAlignment(
      alignment,
      ayahCount: currentAyahSha256.length,
    ).isNotEmpty) {
      return SpanIndex._(const [], SyncUnavailableReason.invalid, 0);
    }
    var stale = 0;
    final usable = <AlignmentSpan>[];
    for (final s in alignment.spans) {
      if (s.status != MappingStatus.verified) continue;
      final fresh = s.ayahs.every(
        (n) =>
            alignment.ayahSha256[n] != null &&
            alignment.ayahSha256[n] == currentAyahSha256[n],
      );
      if (!fresh) {
        stale++;
        continue;
      }
      usable.add(s);
    }
    usable.sort((a, b) => a.startMs.compareTo(b.startMs));
    return SpanIndex._(
      List.unmodifiable(usable),
      usable.isEmpty ? SyncUnavailableReason.noVerifiedSpans : null,
      stale,
    );
  }

  final List<AlignmentSpan> _spans;

  /// Null when at least one verified span is usable.
  final SyncUnavailableReason? unavailableReason;

  /// Verified spans dropped because their ayah text changed since alignment.
  final int excludedStale;

  List<AlignmentSpan> get spans => _spans;
  bool get isUsable => _spans.isNotEmpty;

  /// The verified span playing at [positionMs], or null (gap, intro, none).
  /// Binary search: O(log n), so long recordings stay cheap.
  AlignmentSpan? activeAt(int positionMs) {
    var lo = 0;
    var hi = _spans.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final s = _spans[mid];
      if (positionMs < s.startMs) {
        hi = mid - 1;
      } else if (positionMs >= s.endMs) {
        lo = mid + 1;
      } else {
        return s;
      }
    }
    return null;
  }

  /// Where a tap on [ayah] should start: the earliest verified
  /// **explanation** span dedicated to that ayah alone; if there is none, the
  /// earliest verified explanation it shares with other ayahs. Recitation
  /// (`reading`) spans are never used for this: a tap asks for the Sheikh's
  /// explanation, not his recitation. Null if none exists.
  AlignmentSpan? explanationForAyah(int ayah) => pickExplanation(
    _spans,
    ayah,
    isExplanation: (s) => s.kind == SpanKind.explanation,
    ayahsOf: (s) => s.ayahs,
  );

  /// The verified span where the Sheikh **reads** [ayah] alone (used by
  /// "Play Recitation + Tafsir" before his explanation). Null if none.
  AlignmentSpan? readingForAyah(int ayah) => _spans
      .where((s) => s.kind == SpanKind.reading && s.ayahs.length == 1)
      .where((s) => s.ayahs.single == ayah)
      .firstOrNull;

  /// Every verified explanation span for [ayah], in time order (an ayah may be
  /// explained more than once).
  List<AlignmentSpan> explanationsForAyah(int ayah) => [
    for (final s in _spans)
      if (s.kind == SpanKind.explanation && s.ayahs.contains(ayah)) s,
  ];

  /// Ayahs that have at least one verified span.
  Set<int> get mappedAyahs => {for (final s in _spans) ...s.ayahs};

  /// Ayahs that have at least one verified explanation span.
  Set<int> get explainedAyahs => {
    for (final s in _spans)
      if (s.kind == SpanKind.explanation) ...s.ayahs,
  };
}
