import 'dart:io';

import 'package:sheekhcali/features/quran/data/quran_metadata_repository.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_metadata.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';

/// The bundled Quran text assets, read straight from disk and checked with
/// the app's own [parseSurahAsset]. Widget tests use this because large
/// assets loaded through the asset bundle never complete under the test's
/// fake clock. The files and the verification are the same as in the app.
class FileQuranTextRepository implements QuranTextRepository {
  const FileQuranTextRepository();

  @override
  Future<QuranTextAvailability> surah(int number) async {
    final file = File(BundledQuranTextRepository.assetPath(number));
    if (!file.existsSync()) {
      return const QuranTextUnavailable(reasons: ['missing']);
    }
    final parsed = parseSurahAsset(file.readAsStringSync());
    return parsed == null
        ? const QuranTextUnavailable(reasons: ['integrity'])
        : QuranTextVerified(parsed);
  }
}

/// The bundled metadata asset, read from disk, checked by the app's own
/// [parseQuranMetadata].
class FileQuranMetadataRepository implements QuranMetadataRepository {
  const FileQuranMetadataRepository();

  @override
  Future<QuranMetadataAvailability> load() async {
    final parsed = parseQuranMetadata(
      File(BundledQuranMetadataRepository.assetPath).readAsStringSync(),
    );
    return parsed == null
        ? const QuranMetadataUnavailable(blockers: ['integrity'])
        : QuranMetadataAvailable(parsed);
  }
}

/// No verified metadata: the fail-closed state.
class UnavailableQuranMetadataRepository implements QuranMetadataRepository {
  const UnavailableQuranMetadataRepository();

  @override
  Future<QuranMetadataAvailability> load() async =>
      const QuranMetadataUnavailable(blockers: ['integrity']);
}
