import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_metadata.dart';

/// **Synthetic test data, not Quran metadata.** Names are deliberately fake
/// ("Synthetic chapter …", Arabic "اختبار" = "test"), so this fixture can
/// never be mistaken for real surah data. It exercises the index UI: lists,
/// search, RTL and navigation. It is never bundled with the app.
final syntheticQuranMetadata = QuranMetadata(
  source: QuranMetadataSource(
    name: 'synthetic-test-fixture',
    version: '0',
    sha256: 'n/a',
  ),
  surahs: [
    SurahInfo(
      number: 1,
      nameArabic: 'اِخْتِبَارٌ أَوَّل',
      nameTransliterated: 'Ikhtibar-Awwal',
      nameEnglish: 'Synthetic chapter one',
      ayahCount: 3,
      revelation: RevelationPlace.makki,
    ),
    SurahInfo(
      number: 2,
      nameArabic: 'اختبار ثان',
      nameTransliterated: 'Ikhtibar-Thani',
      nameEnglish: 'Synthetic chapter two',
      ayahCount: 1,
      revelation: RevelationPlace.madani,
    ),
    SurahInfo(
      number: 12,
      nameArabic: 'اختبار أخير',
      nameTransliterated: 'Ikhtibar-Akhir',
      nameEnglish: 'Synthetic chapter twelve',
      ayahCount: 11,
      revelation: RevelationPlace.makki,
    ),
  ],
  juzs: [
    JuzInfo(number: 1, startSurah: 1, startAyah: 1),
    JuzInfo(number: 2, startSurah: 2, startAyah: 1),
  ],
);

class SyntheticQuranMetadataRepository implements QuranMetadataRepository {
  const SyntheticQuranMetadataRepository();

  @override
  Future<QuranMetadataAvailability> load() async =>
      QuranMetadataAvailable(syntheticQuranMetadata);
}
