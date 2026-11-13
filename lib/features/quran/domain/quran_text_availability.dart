import 'package:flutter/foundation.dart';

/// One ayah exactly as stored in the verified source asset.
@immutable
class Ayah {
  const Ayah({
    required this.surah,
    required this.number,
    required this.text,
    required this.sha256,
    String? displayText,
  }) : displayText = displayText ?? text;

  final int surah;

  /// The source's own numbering (Tanzil, Hafs/Kufan count).
  final int number;

  /// Verbatim source text. Never normalised, trimmed or edited.
  final String text;
  final String sha256;

  /// What the reader shows and copies for this ayah: [text] itself, except
  /// for ayah 1 of a surah whose source line starts with the basmala (surahs
  /// 2–114 but 9), where it is the exact remainder after that prefix. The
  /// basmala is then shown, unnumbered, as [SurahText.basmalaHeading].
  final String displayText;
}

/// Provenance of the installed text (QURAN_AND_AUDIO_ACCURACY §2.3).
@immutable
class QuranTextSource {
  const QuranTextSource({
    required this.name,
    required this.script,
    required this.version,
    required this.homepage,
    required this.retrievedAt,
    required this.fileSha256,
    required this.licence,
    required this.crossCheckSource,
    required this.crossCheckMatched,
  });

  final String name;
  final String script;
  final String version;
  final String homepage;
  final String retrievedAt;
  final String fileSha256;

  /// The source's licence block, verbatim (Tanzil terms require it).
  final String licence;
  final String? crossCheckSource;

  /// True when every ayah's letter skeleton matched the independent source.
  final bool crossCheckMatched;
}

@immutable
class SurahText {
  const SurahText({
    required this.number,
    required this.nameArabic,
    required this.nameTransliterated,
    required this.nameEnglish,
    required this.revelation,
    required this.ayahs,
    required this.source,
    required this.numberingConvention,
    required this.basmalaIsAyahOne,
    this.basmalaHeading,
    this.reviewer,
    this.reviewedAt,
  });

  final int number;
  final String nameArabic;
  final String nameTransliterated;
  final String nameEnglish;

  /// As stated by the source metadata ("Meccan" / "Medinan").
  final String revelation;
  final List<Ayah> ayahs;
  final QuranTextSource source;
  final String numberingConvention;
  final bool basmalaIsAyahOne;

  /// The basmala shown above the text, unnumbered: the exact bytes the source
  /// prefixes to this surah's ayah 1 (so 95 and 97 keep their "بِّسْمِ").
  /// Null for Al-Fatiha (where it is ayah 1) and At-Tawbah (none).
  final String? basmalaHeading;

  /// Named reviewer's on-device sign-off (C-27). Null while pending.
  final String? reviewer;
  final String? reviewedAt;

  bool get reviewerSignedOff => reviewer != null && reviewedAt != null;

  Ayah? ayah(int n) {
    for (final a in ayahs) {
      if (a.number == n) return a;
    }
    return null;
  }
}

/// Whether the reader can show Quran text (QURAN_AND_AUDIO_ACCURACY §3.5).
///
/// Text can only come from an imported, checksum-verified source asset. There
/// is deliberately no way to construct it by hand in the app.
@immutable
sealed class QuranTextAvailability {
  const QuranTextAvailability();
}

/// No verified text is installed for this surah. [reasons] explains why.
final class QuranTextUnavailable extends QuranTextAvailability {
  const QuranTextUnavailable({required this.reasons});

  final List<String> reasons;
}

/// Verified text is installed: automated checks passed at import time and
/// again at load time (per-ayah SHA-256). [SurahText.reviewerSignedOff] says
/// whether the reviewer's on-device check is also done.
final class QuranTextVerified extends QuranTextAvailability {
  const QuranTextVerified(this.surah);

  final SurahText surah;
}
