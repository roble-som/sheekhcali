import 'package:flutter/foundation.dart';

import 'alignment.dart';

/// AI-assisted **candidate** segments for a recording (C-28): where the
/// analysis of the recording suggests the Sheikh explains each ayah.
///
/// Candidates are never verified facts. They exist so that the reviewer can
/// hear a proposed segment by tapping its ayah (debug/testing builds only,
/// always labelled "unreviewed") and approve or correct it through the review
/// workflow (docs/review/AL_FATIHA_TAFSIR_REVIEW.md). Only reviewed spans in
/// the production mapping ([TafsirAlignment]) count as verified.
@immutable
class CandidateSet {
  const CandidateSet({
    required this.recordingSha256,
    required this.recordingDurationMs,
    required this.ayahSha256,
    required this.spans,
  });

  final String recordingSha256;
  final int recordingDurationMs;

  /// The ayah texts the candidates were made for (same as the mapping).
  final Map<int, String> ayahSha256;
  final List<CandidateSpan> spans;

  factory CandidateSet.fromJson(Map<String, dynamic> j) => CandidateSet(
    recordingSha256: j['recordingSha256'] as String,
    recordingDurationMs: j['recordingDurationMs'] as int,
    ayahSha256: {
      for (final e in (j['ayahSha256'] as Map<String, dynamic>).entries)
        int.parse(e.key): e.value as String,
    },
    spans: [
      for (final s in (j['spans'] as List).cast<Map<String, dynamic>>())
        CandidateSpan.fromJson(s),
    ],
  );

  /// Whether these candidates belong to exactly this recording and these
  /// ayah texts, and are well-formed (inside the recording, start < end).
  bool isUsableFor({
    required String recordingSha256,
    required Map<int, String> currentAyahSha256,
  }) {
    if (recordingSha256 != this.recordingSha256) return false;
    for (final e in ayahSha256.entries) {
      if (currentAyahSha256[e.key] != e.value) return false;
    }
    return spans.every(
      (s) =>
          s.startMs >= 0 &&
          s.startMs < s.endMs &&
          s.endMs <= recordingDurationMs &&
          s.ayahs.every(ayahSha256.containsKey),
    );
  }

  /// The candidate **explanation** of [ayah]: a segment for that ayah alone if
  /// there is one, otherwise one explaining it together with other ayahs.
  /// Recitation spans are never returned.
  CandidateSpan? explanationForAyah(int ayah) => pickExplanation(
    spans,
    ayah,
    isExplanation: (s) => s.kind == SpanKind.explanation,
    ayahsOf: (s) => s.ayahs,
  );
}

@immutable
class CandidateSpan {
  const CandidateSpan({
    required this.id,
    required this.kind,
    required this.ayahs,
    required this.startMs,
    required this.endMs,
    required this.confidence,
  });

  final String id;
  final SpanKind kind;
  final List<int> ayahs;
  final int startMs;
  final int endMs;

  /// 'high', 'medium' or 'low': how strong the evidence was. Not a promise.
  final String confidence;

  factory CandidateSpan.fromJson(Map<String, dynamic> j) => CandidateSpan(
    id: j['id'] as String,
    kind: SpanKind.values.byName(j['kind'] as String),
    ayahs: (j['ayahs'] as List).cast<int>(),
    startMs: j['startMs'] as int,
    endMs: j['endMs'] as int,
    confidence: j['confidence'] as String,
  );
}

/// Picks the explanation of [ayah] among [spans]: the first span explaining
/// that ayah alone, else the first explaining it together with others.
T? pickExplanation<T>(
  Iterable<T> spans,
  int ayah, {
  required bool Function(T) isExplanation,
  required List<int> Function(T) ayahsOf,
}) {
  T? shared;
  for (final s in spans) {
    if (!isExplanation(s) || !ayahsOf(s).contains(ayah)) continue;
    if (ayahsOf(s).length == 1) return s;
    shared ??= s;
  }
  return shared;
}

/// The segment playing because the user tapped an ayah.
@immutable
class AyahSegment {
  const AyahSegment({
    required this.ayah,
    required this.ayahs,
    required this.startMs,
    required this.endMs,
    required this.reviewed,
    required this.sourceId,
    this.confidence,
    this.finished = false,
  });

  factory AyahSegment.reviewed(int ayah, AlignmentSpan s) => AyahSegment(
    ayah: ayah,
    ayahs: s.ayahs,
    startMs: s.startMs,
    endMs: s.endMs,
    reviewed: true,
    sourceId: s.id,
  );

  factory AyahSegment.candidate(int ayah, CandidateSpan s) => AyahSegment(
    ayah: ayah,
    ayahs: s.ayahs,
    startMs: s.startMs,
    endMs: s.endMs,
    reviewed: false,
    sourceId: s.id,
    confidence: s.confidence,
  );

  /// The ayah the user tapped.
  final int ayah;

  /// All ayahs the segment explains (more than one for a shared segment).
  final List<int> ayahs;
  final int startMs;
  final int endMs;

  /// True only for a span the reviewer signed off (C-27).
  final bool reviewed;
  final String sourceId;
  final String? confidence;

  /// Playback reached [endMs] and stopped there.
  final bool finished;

  AyahSegment asFinished() => AyahSegment(
    ayah: ayah,
    ayahs: ayahs,
    startMs: startMs,
    endMs: endMs,
    reviewed: reviewed,
    sourceId: sourceId,
    confidence: confidence,
    finished: true,
  );
}
