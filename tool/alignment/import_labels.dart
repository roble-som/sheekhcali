// Turns the reviewer's Audacity label export into the bundled alignment file.
//
// Usage (from the repo root):
//   dart run tool/alignment/import_labels.dart \
//     --labels <labels.txt> --recording <original.mp3> \
//     [--sign-off --reviewer "<full name>"]
//
// * The recording is identified by its SHA-256: it must be byte-identical to
//   the one the alignment file is bound to (R3), or nothing is written.
// * Ayah hashes are copied from the imported Quran text asset, so a mapping
//   can never silently attach to different text.
// * Without --sign-off every span is a draft (never highlights). With
//   --sign-off and --reviewer, non-draft spans become verified with the
//   reviewer's name and today's date. Lines labelled DRAFT stay drafts.
// * The result must pass validateAlignment (no overlaps, inside the
//   recording, valid ayahs, signed). Otherwise nothing is written.
// * The original recording is only read, never modified.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/labels.dart';

const _alignmentPath = 'assets/content/alignments/al-fatiha-tafsir-r3.json';
const _textPath = 'assets/quran/tanzil-uthmani-1.1/surah-001.json';

Never _fail(String m) {
  stderr.writeln('IMPORT FAILED: $m');
  exit(1);
}

Future<void> main(List<String> argv) async {
  String? arg(String name) {
    final i = argv.indexOf('--$name');
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  }

  final labelsPath = arg('labels') ?? _fail('--labels is required');
  final recordingPath = arg('recording') ?? _fail('--recording is required');
  final signOff = argv.contains('--sign-off');
  final reviewer = arg('reviewer');
  if (signOff && (reviewer == null || reviewer.trim().isEmpty)) {
    _fail('--sign-off needs --reviewer "<full name>"');
  }

  final existing = jsonDecode(
    File(_alignmentPath).readAsStringSync(),
  ) as Map<String, dynamic>;
  final expectedSha = existing['recordingSha256'] as String;
  final actualSha = (await sha256.bind(File(recordingPath).openRead()).first)
      .toString();
  if (actualSha != expectedSha) {
    _fail(
      'Recording SHA-256 $actualSha is not the bound recording $expectedSha',
    );
  }

  final text =
      jsonDecode(File(_textPath).readAsStringSync()) as Map<String, dynamic>;
  final ayahs = (text['ayahs'] as List).cast<Map<String, dynamic>>();

  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final List<AlignmentSpan> spans;
  try {
    spans = spansFromLabels(
      parseAudacityLabels(File(labelsPath).readAsStringSync()),
      signOff: signOff,
      reviewer: reviewer,
      date: today,
    );
  } on LabelError catch (e) {
    _fail('$e');
  }

  final alignment = TafsirAlignment(
    recordingSha256: expectedSha,
    recordingDurationMs: existing['recordingDurationMs'] as int,
    surah: 1,
    textSourceSha256: (text['source'] as Map)['fileSha256'] as String,
    ayahSha256: {
      for (final a in ayahs) a['number'] as int: a['sha256'] as String,
    },
    spans: spans,
  );
  final issues = validateAlignment(alignment, ayahCount: ayahs.length);
  if (issues.isNotEmpty) _fail(issues.join('\n'));

  final out = {
    ...existing,
    'review': {
      'reviewer': signOff ? reviewer : 'owner (C-27)',
      'status': signOff
          ? 'signed off $today: ${alignment.verifiedCount} verified, ${alignment.draftCount} draft'
          : 'pending: ${spans.length} draft spans, none verified',
    },
    'textSourceSha256': alignment.textSourceSha256,
    'ayahSha256': {
      for (final e in alignment.ayahSha256.entries) '${e.key}': e.value,
    },
    'spans': [for (final s in spans) s.toJson()],
  };
  File(
    _alignmentPath,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln(
    'OK: ${spans.length} spans (${alignment.verifiedCount} verified, '
    '${alignment.draftCount} draft) written to $_alignmentPath',
  );
}
