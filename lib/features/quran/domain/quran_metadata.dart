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
  const QuranMetadata({
    required this.source,
    required this.surahs,
    required this.juzs,
  });

  final QuranMetadataSource source;
  final List<SurahInfo> surahs;
  final List<JuzInfo> juzs;

  SurahInfo? surah(int number) {
    for (final s in surahs) {
      if (s.number == number) return s;
    }
    return null;
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
