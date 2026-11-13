import 'alignment.dart';

/// One line of an Audacity label export: `start<TAB>end<TAB>label`, times in
/// seconds. This is the review workflow's input format
/// (docs/review/AL_FATIHA_TAFSIR_REVIEW.md).
class LabelLine {
  const LabelLine(this.lineNumber, this.startMs, this.endMs, this.text);

  final int lineNumber;
  final int startMs;
  final int endMs;
  final String text;
}

class LabelError implements Exception {
  LabelError(this.lineNumber, this.message);

  final int lineNumber;
  final String message;

  @override
  String toString() => 'line $lineNumber: $message';
}

/// Parses an Audacity label export. Point labels (start == end) and malformed
/// lines are errors; blank lines and Audacity's `\` frequency lines are skipped.
List<LabelLine> parseAudacityLabels(String raw) {
  final out = <LabelLine>[];
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.startsWith('\\')) continue;
    final parts = line.split('\t');
    if (parts.length < 3) {
      throw LabelError(i + 1, 'expected "start<TAB>end<TAB>label"');
    }
    final start = double.tryParse(parts[0].trim());
    final end = double.tryParse(parts[1].trim());
    if (start == null || end == null) throw LabelError(i + 1, 'bad time');
    out.add(
      LabelLine(
        i + 1,
        (start * 1000).round(),
        (end * 1000).round(),
        parts.sublist(2).join('\t').trim(),
      ),
    );
  }
  return out;
}

/// Label grammar (case-insensitive):
///   `reading 1`, `explanation 1`, `explanation 3-4`, `explanation 3,5`
///   `intro`, `qa`
/// A leading `DRAFT` marks a machine draft; such lines are imported only as
/// drafts and can never be signed off by the importer.
({SpanKind kind, List<int> ayahs, bool draft}) parseLabelText(
  String text,
  int lineNumber,
) {
  var t = text.trim();
  var draft = false;
  if (t.toUpperCase().startsWith('DRAFT')) {
    draft = true;
    t = t.substring(5).trim();
  }
  final m = RegExp(
    r'^(reading|explanation|intro|qa)\b\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(t);
  if (m == null) {
    throw LabelError(lineNumber, 'unknown label "$text"');
  }
  final kind = SpanKind.values.byName(m[1]!.toLowerCase());
  final rest = m[2]!.replaceAll('?', '').trim();
  final ayahs = <int>[];
  if (rest.isNotEmpty) {
    for (final part in rest.split(RegExp(r'\s*,\s*'))) {
      final range = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(part);
      if (range != null) {
        final a = int.parse(range[1]!);
        final b = int.parse(range[2]!);
        if (b < a) throw LabelError(lineNumber, 'bad range "$part"');
        for (var n = a; n <= b; n++) {
          ayahs.add(n);
        }
      } else if (RegExp(r'^\d+$').hasMatch(part)) {
        ayahs.add(int.parse(part));
      } else {
        throw LabelError(lineNumber, 'bad ayah list "$rest"');
      }
    }
  }
  return (kind: kind, ayahs: ayahs, draft: draft);
}

/// Builds spans from labels. With [signOff], every non-draft span becomes
/// `verified` with [reviewer] and [date]; otherwise everything stays `draft`.
List<AlignmentSpan> spansFromLabels(
  List<LabelLine> labels, {
  required bool signOff,
  String? reviewer,
  String? date,
}) {
  if (signOff &&
      (reviewer == null || reviewer.trim().isEmpty || date == null)) {
    throw ArgumentError('Sign-off needs a reviewer name and a date');
  }
  final spans = <AlignmentSpan>[];
  for (final l in labels) {
    final p = parseLabelText(l.text, l.lineNumber);
    final verified = signOff && !p.draft;
    spans.add(
      AlignmentSpan(
        id: 's${l.lineNumber.toString().padLeft(3, '0')}',
        startMs: l.startMs,
        endMs: l.endMs,
        kind: p.kind,
        ayahs: p.ayahs,
        status: verified ? MappingStatus.verified : MappingStatus.draft,
        reviewer: verified ? reviewer : null,
        reviewedAt: verified ? date : null,
        origin: p.draft ? 'asr-draft' : 'human',
      ),
    );
  }
  spans.sort((a, b) => a.startMs.compareTo(b.startMs));
  return spans;
}
