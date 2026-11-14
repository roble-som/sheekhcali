import 'package:flutter/foundation.dart';

/// Where a surah was revealed, as stated by the metadata source.
enum RevelationPlace { makki, madani }

/// One surah, exactly as listed by the verified metadata source. No value here
/// may be typed in by hand (QURAN_AND_AUDIO_ACCURACY §3.2).
@immutable
class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.nameTransliterated,
    required this.nameEnglish,
    required this.ayahCount,
    required this.revelation,
  });

  final int number;

  /// Stored byte for byte as supplied; displayed as is.
  final String nameArabic;
  final String nameTransliterated;
  final String nameEnglish;
  final int ayahCount;
  final RevelationPlace revelation;
}

/// The start of one juz, as an ayah reference from the source.
@immutable
class JuzInfo {
  const JuzInfo({
    required this.number,
    required this.startSurah,
    required this.startAyah,
  });

  final int number;
  final int startSurah;
  final int startAyah;
}

/// The first ayah of one Madinah Mushaf page, as listed by the source.
@immutable
class PageInfo {
  const PageInfo({
    required this.number,
    required this.startSurah,
    required this.startAyah,
  });

  final int number;
  final int startSurah;
  final int startAyah;
}

/// Consecutive ayahs of one surah on one page.
@immutable
class PageSegment {
  const PageSegment(this.surah, this.firstAyah, this.lastAyah);

  final int surah;
  final int firstAyah;
  final int lastAyah;

  /// The surah begins on this page (its header and basmala are shown here).
  bool get startsSurah => firstAyah == 1;

  @override
  bool operator ==(Object other) =>
      other is PageSegment &&
      other.surah == surah &&
      other.firstAyah == firstAyah &&
      other.lastAyah == lastAyah;

  @override
  int get hashCode => Object.hash(surah, firstAyah, lastAyah);

  @override
  String toString() => '$surah:$firstAyah-$lastAyah';
}

/// Provenance of the installed metadata (QURAN_AND_AUDIO_ACCURACY §2.3).
@immutable
class QuranMetadataSource {
  const QuranMetadataSource({
    required this.name,
    required this.version,
    required this.sha256,
  });

  final String name;
  final String version;
  final String sha256;
}

@immutable
class QuranMetadata {
  QuranMetadata({
    required this.source,
    required this.surahs,
    required this.juzs,
    this.pages = const [],
  }) : _surahStart = _starts(surahs);

  final QuranMetadataSource source;
  final List<SurahInfo> surahs;
  final List<JuzInfo> juzs;

  /// Madinah Mushaf page starts (604), or empty when the installed metadata
  /// has none. Page mode is offered only when they are present.
  final List<PageInfo> pages;

  /// Index of each surah's first ayah in the whole Quran (0-based).
  final List<int> _surahStart;

  static List<int> _starts(List<SurahInfo> surahs) {
    var running = 0;
    return List.unmodifiable([
      for (final s in surahs) (running += s.ayahCount) - s.ayahCount,
    ]);
  }

  bool get hasPages => pages.isNotEmpty;
  int get pageCount => pages.length;

  SurahInfo? surah(int number) {
    for (final s in surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// Whether [surah]:[ayah] exists.
  bool isValid(int surah, int ayah) =>
      surah >= 1 &&
      surah <= surahs.length &&
      ayah >= 1 &&
      ayah <= surahs[surah - 1].ayahCount;

  int _global(int surah, int ayah) => _surahStart[surah - 1] + ayah - 1;

  /// The page holding [surah]:[ayah] (null without pages or for an invalid
  /// reference).
  int? pageOf(int surah, int ayah) {
    if (!hasPages || !isValid(surah, ayah)) return null;
    final g = _global(surah, ayah);
    var lo = 0;
    var hi = pages.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      final p = pages[mid];
      if (_global(p.startSurah, p.startAyah) <= g) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return pages[lo].number;
  }

  /// The ayahs on [page], in reading order, one segment per surah.
  List<PageSegment> pageSegments(int page) {
    if (page < 1 || page > pages.length) return const [];
    final start = pages[page - 1];
    final first = _global(start.startSurah, start.startAyah);
    final end = page == pages.length
        ? _surahStart.last + surahs.last.ayahCount
        : _global(pages[page].startSurah, pages[page].startAyah);
    final out = <PageSegment>[];
    var surah = start.startSurah;
    var g = first;
    while (g < end) {
      final surahEnd = _surahStart[surah - 1] + surahs[surah - 1].ayahCount;
      final last = (end < surahEnd ? end : surahEnd) - 1;
      out.add(
        PageSegment(
          surah,
          g - _surahStart[surah - 1] + 1,
          last - _surahStart[surah - 1] + 1,
        ),
      );
      g = last + 1;
      surah++;
    }
    return List.unmodifiable(out);
  }

  /// The juz holding [surah]:[ayah].
  int? juzOf(int surah, int ayah) {
    if (!isValid(surah, ayah)) return null;
    final g = _global(surah, ayah);
    int? out;
    for (final j in juzs) {
      if (_global(j.startSurah, j.startAyah) <= g) out = j.number;
    }
    return out;
  }
}

/// Whether the index can list anything.
@immutable
sealed class QuranMetadataAvailability {
  const QuranMetadataAvailability();
}

/// No verified metadata is installed. [blockers] names the pending decisions.
final class QuranMetadataUnavailable extends QuranMetadataAvailability {
  const QuranMetadataUnavailable({required this.blockers});

  final List<String> blockers;
}

/// Verified metadata is installed (import, checksum and review done in Phase 3A).
final class QuranMetadataAvailable extends QuranMetadataAvailability {
  const QuranMetadataAvailable(this.metadata);

  final QuranMetadata metadata;
}
