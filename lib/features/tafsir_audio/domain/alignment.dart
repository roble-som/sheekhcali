import 'package:flutter/foundation.dart';

/// What the Sheikh is doing during a span (QURAN_AND_AUDIO_ACCURACY §7.1).
enum SpanKind { reading, explanation, intro, qa }

/// Only [verified] spans may ever highlight anything.
enum MappingStatus { draft, verified }

/// One timed span on the **original** recording's timeline.
@immutable
class AlignmentSpan {
  const AlignmentSpan({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.kind,
    required this.ayahs,
    required this.status,
    this.reviewer,
    this.reviewedAt,
    this.origin = 'human',
    this.transcript,
    this.note,
  });

  final String id;
  final int startMs;
  final int endMs;
  final SpanKind kind;

  /// Target ayahs (empty for intro / Q&A, which highlight nothing).
  final List<int> ayahs;
  final MappingStatus status;
  final String? reviewer;
  final String? reviewedAt;

  /// 'human' or 'asr-draft'. Drafts can never be verified without a reviewer.
  final String origin;

  /// Machine-draft transcript excerpt for the reviewer (C-28). Never shown as
  /// the Sheikh's words in the reader.
  final String? transcript;

  /// Reviewer's note (for example "ayahs 2–4 explained together").
  final String? note;

  bool contains(int ms) => ms >= startMs && ms < endMs;

  factory AlignmentSpan.fromJson(Map<String, dynamic> j) => AlignmentSpan(
    id: j['id'] as String,
    startMs: j['startMs'] as int,
    endMs: j['endMs'] as int,
    kind: SpanKind.values.byName(j['kind'] as String),
    ayahs: (j['ayahs'] as List).cast<int>(),
    status: MappingStatus.values.byName(j['status'] as String),
    reviewer: j['reviewer'] as String?,
    reviewedAt: j['reviewedAt'] as String?,
    origin: (j['origin'] as String?) ?? 'human',
    transcript: j['transcript'] as String?,
    note: j['note'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'startMs': startMs,
    'endMs': endMs,
    'kind': kind.name,
    'ayahs': ayahs,
    'status': status.name,
    'reviewer': reviewer,
    'reviewedAt': reviewedAt,
    'origin': origin,
    if (transcript != null) 'transcript': transcript,
    if (note != null) 'note': note,
  };
}

/// A mapping between one exact recording and one exact text.
///
/// It is valid only for the recording whose SHA-256 is [recordingSha256] and
/// for ayah texts whose SHA-256 values equal [ayahSha256] (ALN-06 in the
/// reference project; QURAN_AND_AUDIO_ACCURACY §7.1).
@immutable
class TafsirAlignment {
  const TafsirAlignment({
    required this.recordingSha256,
    required this.recordingDurationMs,
    required this.surah,
    required this.textSourceSha256,
    required this.ayahSha256,
    required this.spans,
  });

  final String recordingSha256;
  final int recordingDurationMs;
  final int surah;

  /// SHA-256 of the Quran source file the ayah hashes come from.
  final String textSourceSha256;

  /// ayah number → SHA-256 of its text at the time of alignment.
  final Map<int, String> ayahSha256;
  final List<AlignmentSpan> spans;

  factory TafsirAlignment.fromJson(Map<String, dynamic> j) => TafsirAlignment(
    recordingSha256: j['recordingSha256'] as String,
    recordingDurationMs: j['recordingDurationMs'] as int,
    surah: j['surah'] as int,
    textSourceSha256: j['textSourceSha256'] as String,
    ayahSha256: {
      for (final e in (j['ayahSha256'] as Map<String, dynamic>).entries)
        int.parse(e.key): e.value as String,
    },
    spans: [
      for (final s in (j['spans'] as List).cast<Map<String, dynamic>>())
        AlignmentSpan.fromJson(s),
    ],
  );

  int get verifiedCount =>
      spans.where((s) => s.status == MappingStatus.verified).length;
  int get draftCount =>
      spans.where((s) => s.status == MappingStatus.draft).length;
}

/// One problem found by [validateAlignment].
@immutable
class AlignmentIssue {
  const AlignmentIssue(this.spanId, this.code, this.message);

  final String? spanId;
  final String code;
  final String message;

  @override
  String toString() => '${spanId ?? '-'} $code: $message';
}

/// Structural rules (QURAN_AND_AUDIO_ACCURACY §7.2). An alignment with any
/// issue is not used for highlighting at all.
List<AlignmentIssue> validateAlignment(
  TafsirAlignment a, {
  required int ayahCount,
}) {
  final issues = <AlignmentIssue>[];
  final sorted = [...a.spans]..sort((x, y) => x.startMs.compareTo(y.startMs));
  final ids = <String>{};
  for (var i = 0; i < sorted.length; i++) {
    final s = sorted[i];
    if (!ids.add(s.id)) {
      issues.add(AlignmentIssue(s.id, 'duplicate-id', 'Duplicate span id'));
    }
    if (s.startMs < 0 || s.endMs <= s.startMs) {
      issues.add(AlignmentIssue(s.id, 'bad-range', 'Start must be before end'));
    }
    if (s.endMs > a.recordingDurationMs) {
      issues.add(
        AlignmentIssue(s.id, 'past-end', 'Span ends after the recording'),
      );
    }
    final linked = s.kind == SpanKind.reading || s.kind == SpanKind.explanation;
    if (linked && s.ayahs.isEmpty) {
      issues.add(
        AlignmentIssue(s.id, 'no-target', 'Reading/explanation needs an ayah'),
      );
    }
    if (!linked && s.ayahs.isNotEmpty) {
      issues.add(
        AlignmentIssue(
          s.id,
          'unexpected-target',
          'Intro/Q&A must not target ayahs',
        ),
      );
    }
    for (final n in s.ayahs) {
      if (n < 1 || n > ayahCount) {
        issues.add(
          AlignmentIssue(s.id, 'bad-ayah', 'Ayah $n is outside 1–$ayahCount'),
        );
      }
    }
    if (s.status == MappingStatus.verified &&
        (s.reviewer == null ||
            s.reviewer!.trim().isEmpty ||
            s.reviewedAt == null)) {
      issues.add(
        AlignmentIssue(
          s.id,
          'unsigned',
          'Verified span without reviewer and date',
        ),
      );
    }
    if (i > 0 && s.startMs < sorted[i - 1].endMs) {
      issues.add(
        AlignmentIssue(s.id, 'overlap', 'Overlaps ${sorted[i - 1].id}'),
      );
    }
  }
  return issues;
}
