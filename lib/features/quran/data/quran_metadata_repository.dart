import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quran_metadata.dart';

/// Source of surah and juz metadata for the index screens.
abstract interface class QuranMetadataRepository {
  Future<QuranMetadataAvailability> load();
}

/// The verified Tanzil metadata (C-25), imported and cross-checked by
/// `tool/quran/import_metadata.dart`. Fails closed: anything inconsistent
/// lists nothing.
class BundledQuranMetadataRepository implements QuranMetadataRepository {
  BundledQuranMetadataRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const assetPath = 'assets/quran/tanzil-uthmani-1.1/metadata.json';

  @override
  Future<QuranMetadataAvailability> load() async {
    try {
      final raw = await _bundle.loadString(assetPath, cache: false);
      final parsed = parseQuranMetadata(raw);
      return parsed == null
          ? const QuranMetadataUnavailable(blockers: ['integrity'])
          : QuranMetadataAvailable(parsed);
    } on Object {
      return const QuranMetadataUnavailable(blockers: ['missing']);
    }
  }
}

/// Parses and re-checks the metadata asset (114 surahs numbered 1–114 with
/// 6,236 ayahs in total, 30 juz in order, cross-check recorded and, when
/// pages are present, 604 pages in strict reading order from 1:1). Null on
/// any inconsistency.
QuranMetadata? parseQuranMetadata(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  if (json['schema'] != 1) return null;
  final source = json['source'] as Map<String, dynamic>;
  if ((json['crossCheck'] as Map<String, dynamic>?)?['result'] != 'all equal') {
    return null;
  }
  final surahs = [
    for (final s in (json['surahs'] as List).cast<Map<String, dynamic>>())
      SurahInfo(
        number: s['number'] as int,
        nameArabic: s['nameArabic'] as String,
        nameTransliterated: s['nameTransliterated'] as String,
        nameEnglish: s['nameEnglish'] as String,
        ayahCount: s['ayahCount'] as int,
        revelation: switch (s['revelation']) {
          'Meccan' => RevelationPlace.makki,
          'Medinan' => RevelationPlace.madani,
          _ => throw const FormatException('revelation'),
        },
      ),
  ];
  final juzs = [
    for (final j in (json['juzs'] as List).cast<Map<String, dynamic>>())
      JuzInfo(
        number: j['number'] as int,
        startSurah: j['startSurah'] as int,
        startAyah: j['startAyah'] as int,
      ),
  ];
  if (surahs.length != 114 || juzs.length != 30) return null;
  for (var i = 0; i < surahs.length; i++) {
    if (surahs[i].number != i + 1) return null;
  }
  for (var i = 0; i < juzs.length; i++) {
    if (juzs[i].number != i + 1) return null;
  }
  if (surahs.fold<int>(0, (t, s) => t + s.ayahCount) != 6236) return null;
  final pages = [
    for (final p
        in ((json['pages'] as List?) ?? const []).cast<Map<String, dynamic>>())
      PageInfo(
        number: p['number'] as int,
        startSurah: p['startSurah'] as int,
        startAyah: p['startAyah'] as int,
      ),
  ];
  if (pages.isNotEmpty) {
    if (pages.length != 604) return null;
    final checked =
        ((json['crossCheck'] as Map<String, dynamic>)['checked'] as List?)
            ?.cast<String>() ??
        const [];
    if (!checked.any((c) => c.startsWith('Madinah Mushaf page'))) return null;
    var previous = -1;
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      if (p.number != i + 1) return null;
      if (p.startSurah < 1 || p.startSurah > 114) return null;
      if (p.startAyah < 1 || p.startAyah > surahs[p.startSurah - 1].ayahCount) {
        return null;
      }
      var g = p.startAyah - 1;
      for (var s = 0; s < p.startSurah - 1; s++) {
        g += surahs[s].ayahCount;
      }
      if (i == 0 ? g != 0 : g <= previous) return null;
      previous = g;
    }
  }
  return QuranMetadata(
    source: QuranMetadataSource(
      name: source['name'] as String,
      version: source['version'] as String,
      sha256: source['fileSha256'] as String,
    ),
    surahs: List.unmodifiable(surahs),
    juzs: List.unmodifiable(juzs),
    pages: List.unmodifiable(pages),
  );
}

final quranMetadataRepositoryProvider = Provider<QuranMetadataRepository>(
  (ref) => BundledQuranMetadataRepository(),
);

final quranMetadataProvider = FutureProvider<QuranMetadataAvailability>(
  (ref) => ref.watch(quranMetadataRepositoryProvider).load(),
);
