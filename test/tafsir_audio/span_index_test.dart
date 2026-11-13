import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/span_index.dart';

/// Synthetic spans only (fake hashes and times). They test the rules, not any
/// real mapping.
const rec = 'rec-sha';
final hashes = {for (var i = 1; i <= 7; i++) i: 'h$i'};

AlignmentSpan span(
  String id,
  int start,
  int end,
  List<int> ayahs, {
  SpanKind kind = SpanKind.explanation,
  MappingStatus status = MappingStatus.verified,
  String? reviewer = 'Owner',
}) => AlignmentSpan(
  id: id,
  startMs: start,
  endMs: end,
  kind: kind,
  ayahs: ayahs,
  status: status,
  reviewer: status == MappingStatus.verified ? reviewer : null,
  reviewedAt: status == MappingStatus.verified ? '2026-11-13' : null,
);

TafsirAlignment alignment(
  List<AlignmentSpan> spans, {
  String recording = rec,
}) => TafsirAlignment(
  recordingSha256: recording,
  recordingDurationMs: 100000,
  surah: 1,
  textSourceSha256: 'src',
  ayahSha256: hashes,
  spans: spans,
);

void main() {
  group('activeAt', () {
    final index = SpanIndex.build(
      alignment: alignment([
        span('a', 1000, 5000, [1], kind: SpanKind.reading),
        span('b', 5000, 9000, [1]),
        span('c', 12000, 20000, [2, 3]),
      ]),
      loadedRecordingSha256: rec,
      currentAyahSha256: hashes,
    );

    test('inside spans, boundaries are [start, end)', () {
      expect(index.activeAt(1000)?.id, 'a');
      expect(index.activeAt(4999)?.id, 'a');
      expect(index.activeAt(5000)?.id, 'b');
      expect(index.activeAt(12000)?.ayahs, [2, 3]);
    });

    test(
      'gaps, before the first and after the last span highlight nothing',
      () {
        expect(index.activeAt(0), isNull);
        expect(index.activeAt(9000), isNull);
        expect(index.activeAt(11999), isNull);
        expect(index.activeAt(20000), isNull);
        expect(index.activeAt(99999), isNull);
      },
    );

    test('seeking anywhere gives the same answer as playing there', () {
      // activeAt is a pure function of position, so a seek can never leave a
      // stale highlight behind.
      for (final t in [0, 1500, 6000, 10000, 15000, 25000, 1500]) {
        final linear = index.spans.where((s) => s.contains(t)).firstOrNull;
        expect(index.activeAt(t)?.id, linear?.id, reason: 't=$t');
      }
    });

    test('tap on an ayah goes to its explanation, never its recitation', () {
      expect(index.explanationForAyah(1)?.id, 'b'); // not the reading span 'a'
      expect(index.explanationForAyah(3)?.id, 'c'); // explained with ayah 2
      expect(index.explanationForAyah(7), isNull);
      expect(index.mappedAyahs, {1, 2, 3});
      expect(index.explainedAyahs, {1, 2, 3});
    });

    test('a dedicated explanation wins over an earlier shared one', () {
      final both = SpanIndex.build(
        alignment: alignment([
          span('shared', 1000, 5000, [2, 3, 4]),
          span('own4', 6000, 9000, [4]),
        ]),
        loadedRecordingSha256: rec,
        currentAyahSha256: hashes,
      );
      expect(both.explanationForAyah(4)?.id, 'own4');
      expect(both.explanationForAyah(3)?.id, 'shared'); // no dedicated span
    });

    test('an ayah with only a recitation span has no explanation', () {
      final onlyReading = SpanIndex.build(
        alignment: alignment([
          span('r', 0, 1000, [4], kind: SpanKind.reading),
        ]),
        loadedRecordingSha256: rec,
        currentAyahSha256: hashes,
      );
      expect(onlyReading.explanationForAyah(4), isNull);
    });
  });

  test('draft spans never highlight', () {
    final index = SpanIndex.build(
      alignment: alignment([
        span('d', 0, 5000, [1], status: MappingStatus.draft),
      ]),
      loadedRecordingSha256: rec,
      currentAyahSha256: hashes,
    );
    expect(index.activeAt(100), isNull);
    expect(index.unavailableReason, SyncUnavailableReason.noVerifiedSpans);
  });

  test('a different recording disables the whole mapping', () {
    final index = SpanIndex.build(
      alignment: alignment([
        span('a', 0, 5000, [1]),
      ], recording: 'other'),
      loadedRecordingSha256: rec,
      currentAyahSha256: hashes,
    );
    expect(index.activeAt(100), isNull);
    expect(index.unavailableReason, SyncUnavailableReason.recordingMismatch);
  });

  test('a changed ayah text makes its spans stale', () {
    final index = SpanIndex.build(
      alignment: alignment([
        span('a', 0, 5000, [1]),
        span('b', 5000, 9000, [2]),
      ]),
      loadedRecordingSha256: rec,
      currentAyahSha256: {...hashes, 2: 'changed'},
    );
    expect(index.activeAt(100)?.id, 'a');
    expect(index.activeAt(6000), isNull);
    expect(index.excludedStale, 1);
  });

  group('validation (any issue disables the mapping)', () {
    List<String> codes(List<AlignmentSpan> spans) => validateAlignment(
      alignment(spans),
      ayahCount: 7,
    ).map((i) => i.code).toList();

    test('overlap, bad range, past end, bad ayah, unsigned', () {
      expect(
        codes([
          span('a', 0, 5000, [1]),
          span('b', 4000, 6000, [2]),
        ]),
        contains('overlap'),
      );
      expect(
        codes([
          span('a', 5000, 5000, [1]),
        ]),
        contains('bad-range'),
      );
      expect(
        codes([
          span('a', 0, 200000, [1]),
        ]),
        contains('past-end'),
      );
      expect(
        codes([
          span('a', 0, 1000, [8]),
        ]),
        contains('bad-ayah'),
      );
      expect(
        codes([
          span('a', 0, 1000, [1], reviewer: ' '),
        ]),
        contains('unsigned'),
      );
    });

    test('kinds: reading/explanation need ayahs, intro/qa must have none', () {
      expect(
        codes([span('a', 0, 1000, [], kind: SpanKind.explanation)]),
        contains('no-target'),
      );
      expect(
        codes([
          span('a', 0, 1000, [1], kind: SpanKind.intro),
        ]),
        contains('unexpected-target'),
      );
      expect(codes([span('a', 0, 1000, [], kind: SpanKind.qa)]), isEmpty);
    });

    test('an invalid alignment highlights nothing at all', () {
      final index = SpanIndex.build(
        alignment: alignment([
          span('a', 0, 5000, [1]),
          span('b', 4000, 6000, [2]),
        ]),
        loadedRecordingSha256: rec,
        currentAyahSha256: hashes,
      );
      expect(index.activeAt(100), isNull);
      expect(index.unavailableReason, SyncUnavailableReason.invalid);
    });
  });
}
