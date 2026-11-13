import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';

/// Al-Fatiha text accuracy (QURAN_AND_AUDIO_ACCURACY §3). The expected values
/// come from the independent manifest written by the import tool from the
/// Tanzil source file, never from memory.
void main() {
  final assetRaw = File(BundledQuranTextRepository.assetPath(1))
      .readAsStringSync();
  final manifest = jsonDecode(
    File('test/quran/surah-001.manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final assetJson = jsonDecode(assetRaw) as Map<String, dynamic>;
  final surah = parseSurahAsset(assetRaw)!;

  String sha(String s) => sha256.convert(utf8.encode(s)).toString();

  test('source is Tanzil Uthmani 1.1, the approved source (C-25)', () {
    expect(surah.source.name, 'Tanzil Quran Text');
    expect(surah.source.script, 'Uthmani');
    expect(surah.source.version, '1.1');
    expect(surah.source.homepage, 'https://tanzil.net/');
  });

  test('source file checksum is the one recorded at import', () {
    expect(surah.source.fileSha256, manifest['sourceFileSha256']);
    expect(
      surah.source.fileSha256,
      'bf4f57b968d03f4131c070b1e285da9be0e0a108a21c910e872801ca273312c8',
    );
  });

  test(
    'seven ayahs, numbered 1–7 in order, Al-Fatiha metadata from source',
    () {
      expect(surah.number, 1);
      expect(surah.ayahs.length, 7);
      expect(surah.ayahs.length, manifest['ayahCount']);
      expect([for (final a in surah.ayahs) a.number], [1, 2, 3, 4, 5, 6, 7]);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.nameTransliterated, 'Al-Faatiha');
      expect(surah.nameEnglish, 'The Opening');
      expect(surah.revelation, 'Meccan');
    },
  );

  test('every ayah matches the independent manifest byte for byte', () {
    final expected = (manifest['ayahSha256'] as List).cast<String>();
    for (var i = 0; i < 7; i++) {
      expect(sha(surah.ayahs[i].text), expected[i], reason: 'ayah ${i + 1}');
    }
  });

  test('round trip reproduces the exact source lines', () {
    final lines = [for (final a in surah.ayahs) '1|${a.number}|${a.text}']
        .join('\n');
    expect(sha(lines), manifest['sourceLinesSha256']);
  });

  test('numbering convention documented: basmala is ayah 1 (from source)', () {
    expect(surah.basmalaIsAyahOne, isTrue);
    expect(surah.numberingConvention, contains('basmala is ayah 1'));
  });

  test('licence block is carried verbatim, as the Tanzil terms require', () {
    expect(
      surah.source.licence,
      contains('Tanzil Quran Text (Uthmani, Version 1.1)'),
    );
    expect(surah.source.licence, contains('CHANGING IT IS NOT ALLOWED'));
    expect(surah.source.licence, contains('a link is made to tanzil.net'));
  });

  test('independent cross-check matched every ayah', () {
    expect(surah.source.crossCheckMatched, isTrue);
    final results = (assetJson['crossCheck']['results'] as List).cast<Map>();
    expect(results.every((r) => r['letterSkeletonMatch'] == true), isTrue);
  });

  test('text is not Unicode-normalised (no NFC reordering applied)', () {
    // Stored text is exactly the manifest-hashed source; any normalisation
    // would change at least one hash. Spot-check that Uthmani-only code points
    // (alef wasla U+0671, dagger alef U+0670, maddah U+0653) survive.
    final all = surah.ayahs.map((a) => a.text).join();
    expect(all.contains('ٱ'), isTrue);
    expect(all.contains('ٰ'), isTrue);
    expect(all.contains('ٓ'), isTrue);
  });

  test('a single changed character makes the app refuse the text', () {
    final tampered = jsonDecode(assetRaw) as Map<String, dynamic>;
    final ayahs = (tampered['ayahs'] as List).cast<Map<String, dynamic>>();
    final t = ayahs[1]['text'] as String;
    ayahs[1]['text'] = t.replaceFirst('َ', 'ِ'); // fatha -> kasra
    expect(parseSurahAsset(jsonEncode(tampered)), isNull);
  });

  test('the Quran font has a glyph for every code point in the text', () {
    final font = File('assets/fonts/Amiri-Regular.ttf').readAsBytesSync();
    final covered = _cmapCodePoints(font);
    final needed = <int>{for (final a in surah.ayahs) ...a.text.runes};
    final missing = needed.where((c) => !covered.contains(c)).toList();
    expect(
      missing,
      isEmpty,
      reason: missing.map((c) => c.toRadixString(16)).join(','),
    );
  });

  test('reviewer sign-off is recorded only through the review workflow', () {
    // Pending until the owner signs off (C-27); see docs/review/.
    final v = assetJson['verification'] as Map<String, dynamic>;
    expect(v['automated'], 'passed');
    expect(
      surah.reviewerSignedOff,
      v['reviewer'] != null && v['reviewedAt'] != null,
    );
  });
}

/// Minimal TrueType cmap reader (formats 4 and 12).
Set<int> _cmapCodePoints(Uint8List b) {
  final d = ByteData.sublistView(b);
  final numTables = d.getUint16(4);
  var cmapOff = -1;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + 16 * i;
    final tag = String.fromCharCodes(b.sublist(rec, rec + 4));
    if (tag == 'cmap') cmapOff = d.getUint32(rec + 8);
  }
  if (cmapOff < 0) return {};
  final out = <int>{};
  final n = d.getUint16(cmapOff + 2);
  for (var i = 0; i < n; i++) {
    final sub = cmapOff + d.getUint32(cmapOff + 4 + 8 * i + 4);
    final fmt = d.getUint16(sub);
    if (fmt == 4) {
      final segX2 = d.getUint16(sub + 6);
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(sub + 14 + 2 * s);
        final start = d.getUint16(sub + 16 + segX2 + 2 * s);
        for (var c = start; c <= end && c != 0xFFFF; c++) {
          out.add(c);
        }
      }
    } else if (fmt == 12) {
      final groups = d.getUint32(sub + 12);
      for (var g = 0; g < groups; g++) {
        final start = d.getUint32(sub + 16 + 12 * g);
        final end = d.getUint32(sub + 20 + 12 * g);
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}
