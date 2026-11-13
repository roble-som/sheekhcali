// Makes a DRAFT Audacity label file from a whisper.cpp JSON transcript: for
// each transcript segment that looks like a quotation of an Al-Fatiha ayah,
// it writes `DRAFT reading <n>?` with the segment's times.
//
// These are hints for the reviewer only (C-28). They are machine guesses:
// the reviewer must listen, correct the boundaries, and relabel. The import
// tool never signs off DRAFT lines.
//
// Usage: dart run tool/alignment/asr_draft_labels.dart \
//          --asr <whisper.json> --out <draft-labels.txt> [--min 0.6]

import 'dart:convert';
import 'dart:io';

import 'package:sheekhcali/core/text/search_folding.dart';

List<String> _tokens(String s) => s
    .split(RegExp(r'\s+'))
    .map((t) => foldForSearch(t).replaceAll(RegExp(r'[^ء-ي0-9a-z]'), ''))
    .where((t) => t.length >= 2)
    .toList();

int _edit(String a, String b) {
  final d = List.generate(
    a.length + 1,
    (i) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = 0; i <= a.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final c = a[i - 1] == b[j - 1] ? 0 : 1;
      d[i][j] = [
        d[i - 1][j] + 1,
        d[i][j - 1] + 1,
        d[i - 1][j - 1] + c,
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return d[a.length][b.length];
}

/// Share of the ayah's words found (approximately) in the segment.
double _coverage(List<String> ayah, List<String> seg) {
  if (ayah.isEmpty) return 0;
  var hit = 0;
  for (final w in ayah) {
    final tol = w.length > 4 ? 2 : 1;
    if (seg.any((s) => _edit(w, s) <= tol)) hit++;
  }
  return hit / ayah.length;
}

void main(List<String> argv) {
  String? arg(String n) {
    final i = argv.indexOf('--$n');
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  }

  final asrPath = arg('asr');
  final outPath = arg('out');
  final min = double.tryParse(arg('min') ?? '') ?? 0.6;
  if (asrPath == null || outPath == null) {
    stderr.writeln(
      'Usage: --asr <whisper.json> --out <labels.txt> [--min 0.6]',
    );
    exit(1);
  }
  final text = jsonDecode(
    File('assets/quran/tanzil-uthmani-1.1/surah-001.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final ayahs = [
    for (final a in (text['ayahs'] as List).cast<Map<String, dynamic>>())
      (a['number'] as int, _tokens(a['text'] as String)),
  ];
  final asr =
      jsonDecode(File(asrPath).readAsStringSync()) as Map<String, dynamic>;
  final segments = (asr['transcription'] as List).cast<Map<String, dynamic>>();

  final out = StringBuffer();
  var count = 0;
  for (final seg in segments) {
    final offsets = seg['offsets'] as Map<String, dynamic>;
    final from = (offsets['from'] as num) / 1000;
    final to = (offsets['to'] as num) / 1000;
    final words = _tokens(seg['text'] as String);
    final matches = [
      for (final (n, toks) in ayahs)
        if (_coverage(toks, words) >= min) n,
    ];
    if (matches.isEmpty) continue;
    final list = matches.length == 1 ? '${matches.first}' : matches.join(',');
    out.writeln(
      '${from.toStringAsFixed(3)}\t${to.toStringAsFixed(3)}\tDRAFT reading $list?',
    );
    count++;
  }
  File(outPath).writeAsStringSync(out.toString());
  stdout.writeln('Wrote $count DRAFT labels to $outPath (threshold $min).');
}
