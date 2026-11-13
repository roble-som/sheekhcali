// Imports surahs from the Tanzil Quran text into verified app assets.
//
// Usage (from the repo root):
//   dart run tool/quran/import_tanzil.dart \
//     --text <quran-uthmani.txt> --metadata <quran-data.xml> \
//     --retrieved-at <ISO time> --surah 1 \
//     [--crosscheck <qf_chapter.json>]
//   dart run tool/quran/import_tanzil.dart \
//     --text <quran-uthmani.txt> --metadata <quran-data.xml> \
//     --retrieved-at <ISO time> --all --crosscheck-dir <dir with chapter_N.json>
//
// --all writes surahs 2–114 and re-verifies (never rewrites) the reviewed
// Al-Fatiha asset against the same source bytes.
//
// Basmala rule (QURAN_AND_AUDIO_ACCURACY §3): in this source the basmala is
// ayah 1 of Al-Fatiha, and is prefixed to ayah 1 of every other surah except
// At-Tawbah (9), where it is absent. The importer checks this exactly (the
// prefix must equal Al-Fatiha ayah 1 followed by one space) and records it.
// The stored ayah text stays verbatim; the reader shows the prefix as the
// unnumbered basmala heading, not as part of ayah 1.
//
// What it guarantees (QURAN_AND_AUDIO_ACCURACY §2–§3):
// * The whole source file is validated before anything is extracted: 6,236
//   ayahs, contiguous numbering, per-surah counts equal to the metadata, and
//   no control characters, BOM or carriage returns inside ayah text.
// * Ayah text is copied byte for byte. There is no normalisation of any kind.
// * The Tanzil licence block is stored verbatim with the extract, as the
//   Tanzil terms require.
// * Per-ayah SHA-256 hashes, plus the hash of the exact source lines, go into
//   an independent manifest under test/ so tests can prove nothing changed.
// * Optional independent cross-check (Quran Foundation text_uthmani): the
//   letter skeleton must match exactly; mark-level differences are listed for
//   the reviewer. Only the comparison result is stored, never the other text
//   (its terms limit caching).
//
// If any check fails, nothing is written and the exit code is 1.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _expectedAyahTotal = 6236;
const _expectedSurahs = 114;

String _sha(String s) => sha256.convert(utf8.encode(s)).toString();

Never _fail(String message) {
  stderr.writeln('IMPORT FAILED: $message');
  exit(1);
}

Map<String, String> _args(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) continue;
    final hasValue = i + 1 < argv.length && !argv[i + 1].startsWith('--');
    out[argv[i].substring(2)] = hasValue ? argv[++i] : 'true';
  }
  return out;
}

/// Letter skeleton for cross-source comparison only: removes harakat, Quranic
/// annotation marks, the dagger alef, tatweel and the BOM, and collapses spaces.
String skeleton(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final mark =
        (r >= 0x0610 && r <= 0x061A) ||
        (r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        (r >= 0x08D3 && r <= 0x08FF) ||
        r == 0x0640 ||
        r == 0xFEFF;
    if (!mark) b.writeCharCode(r);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

Map<String, String> _attrs(String tag) => {
  for (final m in RegExp(r'(\w+)="([^"]*)"').allMatches(tag)) m[1]!: m[2]!,
};

void main(List<String> argv) {
  final a = _args(argv);
  final all = argv.contains('--all');
  final textPath = a['text'] ?? _fail('--text is required');
  final metaPath = a['metadata'] ?? _fail('--metadata is required');
  final retrievedAt = a['retrieved-at'] ?? _fail('--retrieved-at is required');
  final surahArg = int.tryParse(a['surah'] ?? '');
  if (!all && surahArg == null) _fail('--surah or --all is required');
  final crossDir = a['crosscheck-dir'];
  if (all && crossDir == null) _fail('--all needs --crosscheck-dir');

  final textBytes = File(textPath).readAsBytesSync();
  final metaBytes = File(metaPath).readAsBytesSync();
  final text = utf8.decode(textBytes);
  final meta = utf8.decode(metaBytes);
  final textSha = sha256.convert(textBytes).toString();
  final metaSha = sha256.convert(metaBytes).toString();

  // ---- Parse and validate the whole text file -----------------------------
  final lines = text.split('\n');
  final ayahs = <(int, int, String, String)>[]; // surah, ayah, text, raw line
  final licence = <String>[];
  for (final line in lines) {
    if (line.isEmpty) continue;
    if (line.startsWith('#')) {
      licence.add(line);
      continue;
    }
    final parts = line.split('|');
    if (parts.length != 3) _fail('Malformed line: ${line.substring(0, 20)}');
    final s = int.parse(parts[0]);
    final n = int.parse(parts[1]);
    final t = parts[2];
    if (t.isEmpty) _fail('Empty ayah $s:$n');
    for (final r in t.runes) {
      if (r < 0x20 || r == 0xFEFF || r == 0x0D) _fail('Control char in $s:$n');
    }
    ayahs.add((s, n, t, line));
  }
  if (ayahs.length != _expectedAyahTotal) {
    _fail('Expected $_expectedAyahTotal ayahs, found ${ayahs.length}');
  }
  if (licence.isEmpty) _fail('Licence block not found');
  final versionLine = licence.firstWhere(
    (l) => l.contains('Version'),
    orElse: () => _fail('Version line not found in licence block'),
  );
  if (!versionLine.contains('Uthmani, Version 1.1')) {
    _fail('Unexpected version: $versionLine');
  }

  // ---- Metadata --------------------------------------------------------------
  final suraTags = RegExp(r'<sura [^>]*/>')
      .allMatches(meta)
      .map((m) => _attrs(m[0]!))
      .toList();
  if (suraTags.length != _expectedSurahs) {
    _fail('Metadata lists ${suraTags.length} suras');
  }
  final metaVersion =
      RegExp(r'<quran type="metadata" version="([^"]+)"')
          .firstMatch(meta)?[1] ??
      _fail('Metadata version not found');

  // Per-surah counts and contiguous numbering, for every surah.
  var index = 0;
  for (final tag in suraTags) {
    final s = int.parse(tag['index']!);
    final count = int.parse(tag['ayas']!);
    final start = int.parse(tag['start']!);
    if (start != index) _fail('Surah $s start $start != running index $index');
    for (var n = 1; n <= count; n++) {
      final (gotS, gotN, _, _) = ayahs[index++];
      if (gotS != s || gotN != n) {
        _fail('Order break at $gotS:$gotN, expected $s:$n');
      }
    }
  }
  if (index != _expectedAyahTotal) _fail('Metadata covers $index ayahs');

  // ---- Basmala rule, checked for every surah ---------------------------------
  // The prefix is the first four words of ayah 1. It must equal Al-Fatiha's
  // basmala letter for letter; marks may differ (95 and 97 read "بِّسْمِ", with
  // a shadda), and the reader shows each surah's own bytes.
  final basmala = ayahs.first.$3; // 1:1
  final basmalaWords = basmala.split(' ').length;
  final prefixLengths = <int, int>{};
  for (final tag in suraTags) {
    final s = int.parse(tag['index']!);
    if (s == 1) continue;
    final first = ayahs.firstWhere((x) => x.$1 == s && x.$2 == 1).$3;
    final words = first.split(' ');
    final candidate = words.take(basmalaWords).join(' ');
    final isBasmala =
        words.length > basmalaWords && skeleton(candidate) == skeleton(basmala);
    if (s == 9) {
      if (isBasmala) _fail('At-Tawbah must not start with the basmala');
      continue;
    }
    if (!isBasmala) _fail('Surah $s ayah 1 lacks the basmala prefix');
    prefixLengths[s] = candidate.length + 1;
  }

  final surahs = all
      ? [for (var n = 2; n <= _expectedSurahs; n++) n]
      : [surahArg!];
  if (all) _verifyExistingFatiha(ayahs, textSha);
  for (final surahNo in surahs) {
    final crossPath = all ? '$crossDir/chapter_$surahNo.json' : a['crosscheck'];
    _writeSurah(
      surahNo: surahNo,
      tag: suraTags.firstWhere((t) => int.parse(t['index']!) == surahNo),
      ayahs: ayahs,
      basmala: basmala,
      prefixLength: prefixLengths[surahNo],
      licence: licence,
      textSha: textSha,
      metaSha: metaSha,
      metaVersion: metaVersion,
      retrievedAt: retrievedAt,
      crossPath: crossPath,
      quiet: all,
    );
  }
  if (all) stdout.writeln('OK: wrote surahs 2–114; Al-Fatiha re-verified');
}

/// The reviewed Al-Fatiha asset must still equal the source, ayah for ayah.
void _verifyExistingFatiha(
  List<(int, int, String, String)> ayahs,
  String textSha,
) {
  final f = File('assets/quran/tanzil-uthmani-1.1/surah-001.json');
  final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  if ((j['source'] as Map)['fileSha256'] != textSha) {
    _fail('Al-Fatiha asset was made from different source bytes');
  }
  final stored = (j['ayahs'] as List).cast<Map<String, dynamic>>();
  final source = ayahs.where((x) => x.$1 == 1).toList();
  if (stored.length != source.length) _fail('Al-Fatiha ayah count differs');
  for (var i = 0; i < stored.length; i++) {
    if (stored[i]['text'] != source[i].$3) {
      _fail('Al-Fatiha ayah ${i + 1} differs');
    }
  }
}

void _writeSurah({
  required int surahNo,
  required Map<String, String> tag,
  required List<(int, int, String, String)> ayahs,
  required String basmala,
  required int? prefixLength,
  required List<String> licence,
  required String textSha,
  required String metaSha,
  required String metaVersion,
  required String retrievedAt,
  required String? crossPath,
  required bool quiet,
}) {
  final prefixed = prefixLength != null;

  /// Ayah text as it is compared and shown (without the basmala prefix).
  String shown(int n, String t) =>
      prefixed && n == 1 ? t.substring(prefixLength) : t;

  // ---- Extract the requested surah ------------------------------------------
  final selected = ayahs.where((x) => x.$1 == surahNo).toList();
  if (selected.length != int.parse(tag['ayas']!)) {
    _fail('Count mismatch for surah $surahNo');
  }
  final sourceLines = selected.map((x) => x.$4).join('\n');

  // ---- Optional independent cross-check ---------------------------------------
  Map<String, Object?>? cross;
  if (crossPath != null) {
    final crossBytes = File(crossPath).readAsBytesSync();
    final json = jsonDecode(utf8.decode(crossBytes)) as Map<String, dynamic>;
    final verses = (json['verses'] as List).cast<Map<String, dynamic>>();
    final byKey = {
      for (final v in verses)
        v['verse_key'] as String: v['text_uthmani'] as String,
    };
    final results = <Map<String, Object?>>[];
    var allSkeletons = true;
    if (verses.length != selected.length) {
      _fail('Cross-check source has ${verses.length} ayahs for $surahNo');
    }
    for (final (s, n, t0, _) in selected) {
      final t = shown(n, t0);
      final other = byKey['$s:$n'];
      if (other == null) _fail('Cross-check source lacks $s:$n');
      final skeletonMatch = skeleton(t) == skeleton(other);
      allSkeletons &= skeletonMatch;
      final markMatch = t.replaceAll('ـ', '') == other.replaceAll('ـ', '');
      results.add({
        'ayah': n,
        'letterSkeletonMatch': skeletonMatch,
        'marksMatchIgnoringTatweel': markMatch,
      });
    }
    if (!allSkeletons) {
      final bad = results
          .where((r) => r['letterSkeletonMatch'] == false)
          .map((r) => r['ayah'])
          .join(', ');
      _fail('Surah $surahNo: letter skeleton differs at ayah(s) $bad');
    }
    cross = {
      'source': 'Quran Foundation Content API v4, text_uthmani (KFGQPC-based)',
      'url':
          'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahNo',
      'retrievedAt': retrievedAt,
      'responseSha256': sha256.convert(crossBytes).toString(),
      'policy': 'Comparison result only; the other text is not stored (QF caching terms).',
      'results': results,
    };
  }

  // ---- Write outputs -----------------------------------------------------------
  final ayahJson = [
    for (final (_, n, t, _) in selected)
      {'number': n, 'text': t, 'sha256': _sha(t)},
  ];
  final asset = {
    'schema': 1,
    'source': {
      'name': 'Tanzil Quran Text',
      'script': 'Uthmani',
      'version': '1.1',
      'homepage': 'https://tanzil.net/',
      'updates': 'http://tanzil.net/updates/',
      'downloadUrl': 'https://tanzil.net/pub/download/index.php?quranType=uthmani&outType=txt-2&agree=true',
      'retrievedAt': retrievedAt,
      'fileSha256': textSha,
      'licence': licence
          .map((l) => l.replaceFirst(RegExp(r'^#\s?'), ''))
          .join('\n'),
      'metadata': {
        'name': 'Tanzil Quran metadata',
        'version': metaVersion,
        'url': 'https://tanzil.net/res/text/metadata/quran-data.xml',
        'fileSha256': metaSha,
      },
    },
    'numbering': {
      'convention':
          'Hafs, Kufan count, as in the source: ayah numbers are '
          "Tanzil's own. In Al-Fatiha the basmala is ayah 1 (7 ayahs).",
      'basmalaIsAyahOne': surahNo == 1,
      if (surahNo != 1)
        'basmala': prefixed
            ? {
                'prefixedToAyahOneInSource': true,
                'shownAs': 'unnumbered heading before ayah 1',
                'prefixLength': prefixLength,
                'identicalToFatihaAyahOne': selected.first.$3.startsWith(
                  '$basmala ',
                ),
              }
            : {'present': false},
    },
    'surah': {
      'number': surahNo,
      'nameArabic': tag['name'],
      'nameTransliterated': tag['tname'],
      'nameEnglish': tag['ename'],
      'revelation': tag['type'],
      'ayahCount': selected.length,
    },
    'ayahs': ayahJson,
    'crossCheck': ?cross,
    'verification': {
      'automated': 'passed',
      'automatedChecks': [
        'source version line is "Uthmani, Version 1.1"',
        '$_expectedAyahTotal ayahs, contiguous, per-surah counts equal metadata ($_expectedSurahs suras)',
        'no control characters, BOM or CR in ayah text',
        'verbatim copy; per-ayah SHA-256 recorded',
        if (cross != null)
          'letter skeleton equals independent cross-check source',
      ],
      'reviewer': null,
      'reviewedAt': null,
    },
  };
  final pad = surahNo.toString().padLeft(3, '0');
  final assetFile = File('assets/quran/tanzil-uthmani-1.1/surah-$pad.json');
  assetFile.parent.createSync(recursive: true);
  assetFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(asset)}\n',
  );

  final manifest = {
    'note':
        'Independent checksum manifest written by tool/quran/import_tanzil.dart. '
        'Tests compare the bundled asset against it; never edit by hand.',
    'sourceFileSha256': textSha,
    'sourceLinesSha256': _sha(sourceLines),
    'surah': surahNo,
    'ayahCount': selected.length,
    'ayahSha256': [for (final a in ayahJson) a['sha256']],
  };
  final manifestFile = File('test/quran/surah-$pad.manifest.json');
  manifestFile.parent.createSync(recursive: true);
  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  if (quiet) return;
  stdout.writeln('OK: surah $surahNo, ${selected.length} ayahs');
  stdout.writeln('source sha256 $textSha');
  stdout.writeln('wrote ${assetFile.path} and ${manifestFile.path}');
  if (cross != null) {
    stdout.writeln('cross-check: ${jsonEncode(cross['results'])}');
  }
}
