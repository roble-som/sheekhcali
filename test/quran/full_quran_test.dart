import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';

import '../../tool/quran/import_tanzil.dart' show skeleton;

/// The whole Quran as bundled (Tanzil Uthmani 1.1, C-25). Expected values
/// come from the independent manifests written at import, the metadata asset
/// and the source's own Al-Fatiha basmala, never from memory.
void main() {
  final surahs = <int, SurahText>{
    for (var n = 1; n <= 114; n++)
      n: parseSurahAsset(
        File(BundledQuranTextRepository.assetPath(n)).readAsStringSync(),
      )!,
  };
  final meta = parseQuranMetadata(
    File(BundledQuranMetadataRepository.assetPath).readAsStringSync(),
  )!;
  final basmala = surahs[1]!.ayahs.first.text;
  String sha(String s) => sha256.convert(utf8.encode(s)).toString();

  test('114 surahs, 6,236 ayahs, all from the approved source bytes', () {
    expect(surahs.length, 114);
    expect(surahs.values.fold<int>(0, (t, s) => t + s.ayahs.length), 6236);
    for (final s in surahs.values) {
      expect(
        s.source.fileSha256,
        'bf4f57b968d03f4131c070b1e285da9be0e0a108a21c910e872801ca273312c8',
      );
      expect(s.source.crossCheckMatched, isTrue, reason: 'surah ${s.number}');
    }
  });

  test('every ayah equals its independent manifest, byte for byte', () {
    for (final s in surahs.values) {
      final pad = s.number.toString().padLeft(3, '0');
      final manifest = jsonDecode(
        File('test/quran/surah-$pad.manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final expected = (manifest['ayahSha256'] as List).cast<String>();
      expect(s.ayahs.length, expected.length, reason: 'surah ${s.number}');
      for (var i = 0; i < expected.length; i++) {
        expect(sha(s.ayahs[i].text), expected[i]);
        expect(s.ayahs[i].number, i + 1);
      }
    }
  });

  test('metadata agrees with the text: names, counts, 30 juz', () {
    for (final info in meta.surahs) {
      final s = surahs[info.number]!;
      expect(s.ayahs.length, info.ayahCount, reason: 'surah ${info.number}');
      expect(s.nameArabic, info.nameArabic);
      expect(s.nameTransliterated, info.nameTransliterated);
    }
    expect(meta.juzs.length, 30);
    for (final j in meta.juzs) {
      expect(surahs[j.startSurah]!.ayah(j.startAyah), isNotNull);
    }
  });

  test('basmala: ayah 1 of Al-Fatiha; heading elsewhere; none in 9', () {
    expect(surahs[1]!.basmalaIsAyahOne, isTrue);
    expect(surahs[1]!.basmalaHeading, isNull);
    expect(surahs[9]!.basmalaHeading, isNull);
    expect(surahs[9]!.ayahs.first.displayText, surahs[9]!.ayahs.first.text);
    for (var n = 2; n <= 114; n++) {
      if (n == 9) continue;
      final s = surahs[n]!;
      final heading = s.basmalaHeading;
      expect(heading, isNotNull, reason: 'surah $n');
      final first = s.ayahs.first;
      // Display = exact remainder after the heading and one space.
      expect('$heading ${first.displayText}', first.text, reason: 'surah $n');
      expect(first.displayText, isNotEmpty);
      // Same letters as Al-Fatiha's basmala.
      expect(skeleton(heading!), skeleton(basmala), reason: 'surah $n');
      // Only ayah 1 is ever shortened.
      for (final a in s.ayahs.skip(1)) {
        expect(a.displayText, a.text);
      }
    }
  });

  test('95 and 97 keep their own basmala bytes (with shadda), not 1:1', () {
    for (final n in [95, 97]) {
      final heading = surahs[n]!.basmalaHeading!;
      expect(heading, isNot(basmala));
      expect(surahs[n]!.ayahs.first.text, startsWith(heading));
    }
    final identical = [
      for (var n = 2; n <= 114; n++)
        if (n != 9 && surahs[n]!.basmalaHeading == basmala) n,
    ];
    expect(
      identical.length,
      110,
    ); // 112 surahs with a basmala heading, minus 95 and 97
  });

  test('the reviewed Al-Fatiha asset is unchanged', () {
    final raw = File(BundledQuranTextRepository.assetPath(1))
        .readAsStringSync();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    expect((j['source'] as Map)['retrievedAt'], '2026-11-13T09:19:54Z');
    expect(j['numbering'], isNot(contains('basmala')));
  });
}
