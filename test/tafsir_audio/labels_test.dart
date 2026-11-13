import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/labels.dart';

/// The review workflow's label format. Times below are synthetic.
void main() {
  const export =
      '0.000000\t4.500000\tintro\n'
      '4.500000\t12.250000\treading 1\n'
      '12.250000\t60.000000\texplanation 1\n'
      '\\\t0.0\t0.0\n' // Audacity spectral line: skipped
      '\n'
      '65.0\t80.0\tExplanation 3-4\n'
      '80.0\t90.0\tDRAFT reading 5?\n';

  test('parses Audacity exports to milliseconds', () {
    final lines = parseAudacityLabels(export);
    expect(lines.length, 5);
    expect(lines[1].startMs, 4500);
    expect(lines[1].endMs, 12250);
    expect(lines[3].text, 'Explanation 3-4');
  });

  test('label grammar: kinds, ranges, lists, drafts', () {
    expect(parseLabelText('reading 1', 1).ayahs, [1]);
    expect(parseLabelText('explanation 3-5', 1).ayahs, [3, 4, 5]);
    expect(parseLabelText('explanation 2, 6', 1).ayahs, [2, 6]);
    expect(parseLabelText('QA', 1).kind, SpanKind.qa);
    final d = parseLabelText('DRAFT reading 5?', 1);
    expect(d.draft, isTrue);
    expect(d.ayahs, [5]);
    expect(() => parseLabelText('summary 1', 7), throwsA(isA<LabelError>()));
    expect(() => parseLabelText('reading one', 7), throwsA(isA<LabelError>()));
  });

  test('without sign-off, everything is a draft', () {
    final spans = spansFromLabels(parseAudacityLabels(export), signOff: false);
    expect(spans.every((s) => s.status == MappingStatus.draft), isTrue);
  });

  test('sign-off verifies human spans only, with reviewer and date', () {
    final spans = spansFromLabels(
      parseAudacityLabels(export),
      signOff: true,
      reviewer: 'Owner Name',
      date: '2026-11-13',
    );
    final verified = spans.where((s) => s.status == MappingStatus.verified);
    expect(verified.length, 4);
    expect(verified.every((s) => s.reviewer == 'Owner Name'), isTrue);
    final draft = spans.singleWhere((s) => s.status == MappingStatus.draft);
    expect(draft.origin, 'asr-draft'); // DRAFT lines can't be signed off
  });

  test('sign-off without a reviewer is refused', () {
    expect(
      () => spansFromLabels(
        parseAudacityLabels(export),
        signOff: true,
        date: 'x',
      ),
      throwsArgumentError,
    );
  });

  test('point labels and bad times are rejected by validation or parsing', () {
    expect(
      () => parseAudacityLabels('a\tb\treading 1'),
      throwsA(isA<LabelError>()),
    );
    final spans = spansFromLabels(
      parseAudacityLabels('5.0\t5.0\treading 1'),
      signOff: false,
    );
    final issues = validateAlignment(
      TafsirAlignment(
        recordingSha256: 'r',
        recordingDurationMs: 100000,
        surah: 1,
        textSourceSha256: 's',
        ayahSha256: const {1: 'h'},
        spans: spans,
      ),
      ayahCount: 7,
    );
    expect(issues.map((i) => i.code), contains('bad-range'));
  });
}
