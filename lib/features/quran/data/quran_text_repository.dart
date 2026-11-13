import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quran_text_availability.dart';

/// Source of Quran text for the reader.
abstract interface class QuranTextRepository {
  Future<QuranTextAvailability> surah(int number);
}

/// Loads surahs imported by `tool/quran/import_tanzil.dart` (Tanzil Uthmani
/// 1.1, approved as C-25). Only Al-Fatiha is imported so far.
///
/// Fails closed: if the asset is missing or malformed, or any ayah's text does
/// not match its recorded SHA-256, it reports [QuranTextUnavailable] and the
/// reader shows no text at all.
class BundledQuranTextRepository implements QuranTextRepository {
  BundledQuranTextRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const importedSurahs = {1};

  static String assetPath(int surah) =>
      'assets/quran/tanzil-uthmani-1.1/surah-${surah.toString().padLeft(3, '0')}.json';

  @override
  Future<QuranTextAvailability> surah(int number) async {
    if (!importedSurahs.contains(number)) {
      return const QuranTextUnavailable(reasons: ['not-imported']);
    }
    try {
      final raw = await _bundle.loadString(assetPath(number), cache: false);
      final parsed = parseSurahAsset(raw);
      return parsed == null
          ? const QuranTextUnavailable(reasons: ['integrity'])
          : QuranTextVerified(parsed);
    } on Object {
      return const QuranTextUnavailable(reasons: ['missing']);
    }
  }
}

/// Parses and re-verifies an imported surah asset. Returns null on any
/// inconsistency. Public so tests can exercise the integrity rules directly.
SurahText? parseSurahAsset(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  if (json['schema'] != 1) return null;
  final source = json['source'] as Map<String, dynamic>;
  if (source['name'] != 'Tanzil Quran Text' ||
      source['script'] != 'Uthmani' ||
      source['version'] != '1.1') {
    return null;
  }
  final surah = json['surah'] as Map<String, dynamic>;
  final number = surah['number'] as int;
  final verification = json['verification'] as Map<String, dynamic>;
  if (verification['automated'] != 'passed') return null;

  final ayahs = <Ayah>[];
  final list = (json['ayahs'] as List).cast<Map<String, dynamic>>();
  for (var i = 0; i < list.length; i++) {
    final a = list[i];
    final n = a['number'] as int;
    final text = a['text'] as String;
    final recorded = a['sha256'] as String;
    if (n != i + 1) return null; // contiguous, starting at 1
    if (sha256.convert(utf8.encode(text)).toString() != recorded) return null;
    ayahs.add(Ayah(surah: number, number: n, text: text, sha256: recorded));
  }
  if (ayahs.isEmpty || ayahs.length != surah['ayahCount']) return null;

  final cross = json['crossCheck'] as Map<String, dynamic>?;
  final crossResults = (cross?['results'] as List?)
      ?.cast<Map<String, dynamic>>();
  final numbering = json['numbering'] as Map<String, dynamic>;
  return SurahText(
    number: number,
    nameArabic: surah['nameArabic'] as String,
    nameTransliterated: surah['nameTransliterated'] as String,
    nameEnglish: surah['nameEnglish'] as String,
    revelation: surah['revelation'] as String,
    ayahs: List.unmodifiable(ayahs),
    numberingConvention: numbering['convention'] as String,
    basmalaIsAyahOne: numbering['basmalaIsAyahOne'] as bool,
    reviewer: verification['reviewer'] as String?,
    reviewedAt: verification['reviewedAt'] as String?,
    source: QuranTextSource(
      name: source['name'] as String,
      script: source['script'] as String,
      version: source['version'] as String,
      homepage: source['homepage'] as String,
      retrievedAt: source['retrievedAt'] as String,
      fileSha256: source['fileSha256'] as String,
      licence: source['licence'] as String,
      crossCheckSource: cross?['source'] as String?,
      crossCheckMatched:
          crossResults != null &&
          crossResults.length == ayahs.length &&
          crossResults.every((r) => r['letterSkeletonMatch'] == true),
    ),
  );
}

final quranTextRepositoryProvider = Provider<QuranTextRepository>(
  (ref) => BundledQuranTextRepository(),
);

final surahTextProvider = FutureProvider.family<QuranTextAvailability, int>(
  (ref, number) => ref.watch(quranTextRepositoryProvider).surah(number),
);
