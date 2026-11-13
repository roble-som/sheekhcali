import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quran_metadata.dart';

/// Source of surah and juz metadata for the index screens.
abstract interface class QuranMetadataRepository {
  Future<QuranMetadataAvailability> load();
}

/// The only implementation in Phase 1. Surah names, ayah counts and juz
/// boundaries must come from the approved, verified source (P-03) after
/// review (P-07). Until then nothing is listed; the values are never typed in
/// from memory.
class PendingQuranMetadataRepository implements QuranMetadataRepository {
  const PendingQuranMetadataRepository();

  @override
  Future<QuranMetadataAvailability> load() async =>
      const QuranMetadataUnavailable(blockers: ['P-03', 'P-07']);
}

final quranMetadataRepositoryProvider = Provider<QuranMetadataRepository>(
  (ref) => const PendingQuranMetadataRepository(),
);

final quranMetadataProvider = FutureProvider<QuranMetadataAvailability>(
  (ref) => ref.watch(quranMetadataRepositoryProvider).load(),
);
