import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_metadata.dart';

/// Madinah Mushaf page boundaries: the bundled pages (from the approved Tanzil
/// metadata file) against an independent record of every ayah's page (Quran
/// Foundation `page_number`, test/quran/qf_page_numbers.json).
void main() {
  const assetPath = 'assets/quran/tanzil-uthmani-1.1/metadata.json';
  final raw = File(assetPath).readAsStringSync();
  final meta = parseQuranMetadata(raw)!;
  final qf =
      (jsonDecode(File('test/quran/qf_page_numbers.json').readAsStringSync())
              as Map<String, dynamic>)['pageNumbers']
          as Map<String, dynamic>;
  int qfPage(int surah, int ayah) =>
      ((qf['$surah'] as List)[ayah - 1] as num).toInt();

  test('604 pages, starting at 1:1', () {
    expect(meta.hasPages, isTrue);
    expect(meta.pageCount, 604);
    expect(meta.pages.first.startSurah, 1);
    expect(meta.pages.first.startAyah, 1);
  });

  test('every one of the 6,236 ayahs is on the independent source\'s page', () {
    var n = 0;
    final wrong = <String>[];
    for (final s in meta.surahs) {
      expect((qf['${s.number}'] as List).length, s.ayahCount);
      for (var a = 1; a <= s.ayahCount; a++) {
        n++;
        if (meta.pageOf(s.number, a) != qfPage(s.number, a)) {
          wrong.add('${s.number}:$a');
        }
      }
    }
    expect(n, 6236);
    expect(wrong, isEmpty);
  });

  test('pages partition the Quran: contiguous, in order, none empty', () {
    final seen = <String>[];
    for (var p = 1; p <= 604; p++) {
      final segments = meta.pageSegments(p);
      expect(segments, isNotEmpty, reason: 'page $p');
      for (final seg in segments) {
        expect(seg.firstAyah, lessThanOrEqualTo(seg.lastAyah));
        for (var a = seg.firstAyah; a <= seg.lastAyah; a++) {
          expect(meta.pageOf(seg.surah, a), p, reason: '${seg.surah}:$a');
          seen.add('${seg.surah}:$a');
        }
      }
      // A surah continuing from the previous page starts mid-surah only in
      // the first segment; every later segment starts its surah.
      for (final seg in segments.skip(1)) {
        expect(seg.startsSurah, isTrue, reason: 'page $p $seg');
      }
    }
    final expected = [
      for (final s in meta.surahs)
        for (var a = 1; a <= s.ayahCount; a++) '${s.number}:$a',
    ];
    expect(seen, expected);
  });

  test('pages with a surah transition are the ones the source implies', () {
    // From the independent record: a page shows the start of surah s when
    // QF puts s:1 on it.
    for (final s in meta.surahs) {
      final page = qfPage(s.number, 1);
      expect(
        meta
            .pageSegments(page)
            .any((g) => g.surah == s.number && g.startsSurah),
        isTrue,
        reason: 'surah ${s.number} on page $page',
      );
    }
    // The last page: the last three surahs, whole.
    final last = meta.pageSegments(604);
    expect(last.map((g) => g.surah).toList(), [
      for (var s = 112; s <= 114; s++)
        if (qfPage(s, 1) == 604) s,
    ]);
  });

  test('juz of a page start equals the bundled juz starts', () {
    for (final j in meta.juzs) {
      expect(meta.juzOf(j.startSurah, j.startAyah), j.number);
      if (j.startAyah > 1) {
        expect(meta.juzOf(j.startSurah, j.startAyah - 1), j.number - 1);
      }
    }
  });

  test('invalid references have no page', () {
    expect(meta.pageOf(0, 1), isNull);
    expect(meta.pageOf(1, 8), isNull);
    expect(meta.pageOf(115, 1), isNull);
    expect(meta.pageSegments(0), isEmpty);
    expect(meta.pageSegments(605), isEmpty);
  });

  group('fails closed', () {
    Map<String, dynamic> fresh() => jsonDecode(raw) as Map<String, dynamic>;

    test('a missing page', () {
      final j = fresh();
      (j['pages'] as List).removeAt(300);
      expect(parseQuranMetadata(jsonEncode(j)), isNull);
    });

    test('pages out of order', () {
      final j = fresh();
      final pages = (j['pages'] as List).cast<Map<String, dynamic>>();
      final a = pages[10]['startAyah'];
      pages[10]['startAyah'] = pages[11]['startAyah'];
      pages[11]['startAyah'] = a;
      pages[10]['startSurah'] = pages[11]['startSurah'];
      expect(parseQuranMetadata(jsonEncode(j)), isNull);
    });

    test('a page start beyond its surah', () {
      final j = fresh();
      ((j['pages'] as List)[1] as Map<String, dynamic>)['startAyah'] = 999;
      expect(parseQuranMetadata(jsonEncode(j)), isNull);
    });

    test('no recorded page cross-check', () {
      final j = fresh();
      final checked =
          (j['crossCheck'] as Map<String, dynamic>)['checked'] as List;
      checked.removeWhere((c) => (c as String).startsWith('Madinah Mushaf'));
      expect(parseQuranMetadata(jsonEncode(j)), isNull);
    });

    test('metadata without pages still lists surahs, without page mode', () {
      final j = fresh()..remove('pages');
      final m = parseQuranMetadata(jsonEncode(j))!;
      expect(m.surahs, hasLength(114));
      expect(m.hasPages, isFalse);
      expect(m.pageOf(2, 255), isNull);
    });
  });

  test('a page is never confused with an ayah number', () {
    // Ayah 2:255 sits on a page whose number differs from 255.
    final page = meta.pageOf(2, 255)!;
    expect(page, qfPage(2, 255));
    expect(page, isNot(255));
    expect(PageSegment(2, 1, 5), const PageSegment(2, 1, 5));
    expect(meta.pageSegments(page).first.surah, 2);
  });
}
