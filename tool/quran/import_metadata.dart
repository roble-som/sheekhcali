// Imports the Tanzil Quran metadata (surah names, ayah counts, revelation
// place, juz starts) into a verified app asset for the Quran index.
//
// Usage (from the repo root):
//   dart run tool/quran/import_metadata.dart --metadata <quran-data.xml> \
//     --chapters <qf chapters.json> --juzs <qf juzs.json> \
//     --retrieved-at <ISO time>
//
// Guarantees (QURAN_AND_AUDIO_ACCURACY §3.2):
// * The metadata file must be byte-identical to the one recorded when the
//   approved text (C-25) was imported (its SHA-256 is read from the Al-Fatiha
//   asset).
// * 114 surahs, 6,236 ayahs in total, contiguous starts, 30 juz in order.
// * Every surah's ayah count must equal the bundled text asset and the
//   independent source (Quran Foundation chapters); revelation places must
//   agree; every juz start must equal the independent source.
// * Values are copied, never typed in. If anything fails, nothing is written.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Never _fail(String m) {
  stderr.writeln('IMPORT FAILED: $m');
  exit(1);
}

Map<String, String> _args(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i + 1 < argv.length; i += 2) {
    out[argv[i].replaceFirst('--', '')] = argv[i + 1];
  }
  return out;
}

Map<String, String> _attrs(String tag) => {
  for (final m in RegExp(r'(\w+)="([^"]*)"').allMatches(tag)) m[1]!: m[2]!,
};

void main(List<String> argv) {
  final a = _args(argv);
  final metaPath = a['metadata'] ?? _fail('--metadata is required');
  final chaptersPath = a['chapters'] ?? _fail('--chapters is required');
  final juzsPath = a['juzs'] ?? _fail('--juzs is required');
  final retrievedAt = a['retrieved-at'] ?? _fail('--retrieved-at is required');

  final metaBytes = File(metaPath).readAsBytesSync();
  final metaSha = sha256.convert(metaBytes).toString();
  final fatiha = jsonDecode(
    File('assets/quran/tanzil-uthmani-1.1/surah-001.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final approvedSha =
      ((fatiha['source'] as Map)['metadata'] as Map)['fileSha256'] as String;
  if (metaSha != approvedSha) {
    _fail('Metadata file differs from the approved one ($metaSha)');
  }
  final meta = utf8.decode(metaBytes);
  final version =
      RegExp(r'<quran type="metadata" version="([^"]+)"')
          .firstMatch(meta)?[1] ??
      _fail('Metadata version not found');

  final suras = RegExp(r'<sura [^>]*/>')
      .allMatches(meta)
      .map((m) => _attrs(m[0]!))
      .toList();
  if (suras.length != 114) _fail('Expected 114 suras, found ${suras.length}');
  var running = 0;
  for (var i = 0; i < suras.length; i++) {
    if (int.parse(suras[i]['index']!) != i + 1) _fail('Sura order at $i');
    if (int.parse(suras[i]['start']!) != running) _fail('Sura ${i + 1} start');
    running += int.parse(suras[i]['ayas']!);
  }
  if (running != 6236) _fail('Metadata covers $running ayahs');

  final juzs = RegExp(r'<juz [^>]*/>')
      .allMatches(meta)
      .map((m) => _attrs(m[0]!))
      .toList();
  if (juzs.length != 30) _fail('Expected 30 juz, found ${juzs.length}');

  // ---- Cross-check: bundled text assets ---------------------------------------
  for (final s in suras) {
    final n = int.parse(s['index']!);
    final pad = n.toString().padLeft(3, '0');
    final asset = jsonDecode(
      File('assets/quran/tanzil-uthmani-1.1/surah-$pad.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final count = (asset['ayahs'] as List).length;
    if (count != int.parse(s['ayas']!)) {
      _fail('Surah $n: text has $count ayahs');
    }
  }

  // ---- Cross-check: independent source ----------------------------------------
  final chapters =
      ((jsonDecode(File(chaptersPath).readAsStringSync())
                  as Map<String, dynamic>)['chapters']
              as List)
          .cast<Map<String, dynamic>>();
  if (chapters.length != 114) _fail('Cross-check lists ${chapters.length}');
  final placeMap = {'Meccan': 'makkah', 'Medinan': 'madinah'};
  for (final s in suras) {
    final n = int.parse(s['index']!);
    final c = chapters.firstWhere((c) => c['id'] == n);
    if (c['verses_count'] != int.parse(s['ayas']!)) {
      _fail('Surah $n ayah count differs from the cross-check');
    }
    if (placeMap[s['type']] != c['revelation_place']) {
      _fail('Surah $n revelation place differs from the cross-check');
    }
  }
  final qfJuz = <int, (int, int)>{};
  for (final j
      in ((jsonDecode(File(juzsPath).readAsStringSync())
                  as Map<String, dynamic>)['juzs']
              as List)
          .cast<Map<String, dynamic>>()) {
    final mapping = (j['verse_mapping'] as Map<String, dynamic>).entries.first;
    final surah = int.parse(mapping.key);
    final ayah = int.parse((mapping.value as String).split('-').first);
    qfJuz[j['juz_number'] as int] = (surah, ayah);
  }
  for (final j in juzs) {
    final n = int.parse(j['index']!);
    final mine = (int.parse(j['sura']!), int.parse(j['aya']!));
    if (qfJuz[n] != mine) _fail('Juz $n start $mine differs: ${qfJuz[n]}');
  }

  final out = {
    'schema': 1,
    'source': {
      'name': 'Tanzil Quran metadata',
      'version': version,
      'url': 'https://tanzil.net/res/text/metadata/quran-data.xml',
      'fileSha256': metaSha,
      'licence': 'Tanzil Project, Creative Commons Attribution 3.0',
    },
    'crossCheck': {
      'source': 'Quran Foundation Content API v4 (chapters, juzs)',
      'retrievedAt': retrievedAt,
      'checked': [
        'ayah count of all 114 surahs (also equal to the bundled text)',
        'revelation place of all 114 surahs',
        'start of all 30 juz',
      ],
      'result': 'all equal',
    },
    'surahs': [
      for (final s in suras)
        {
          'number': int.parse(s['index']!),
          'nameArabic': s['name'],
          'nameTransliterated': s['tname'],
          'nameEnglish': s['ename'],
          'ayahCount': int.parse(s['ayas']!),
          'revelation': s['type'],
        },
    ],
    'juzs': [
      for (final j in juzs)
        {
          'number': int.parse(j['index']!),
          'startSurah': int.parse(j['sura']!),
          'startAyah': int.parse(j['aya']!),
        },
    ],
  };
  File(
    'assets/quran/tanzil-uthmani-1.1/metadata.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln('OK: 114 surahs, 30 juz, cross-checked; wrote metadata.json');
}
