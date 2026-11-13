import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran/data/quran_text_repository.dart';
import '../../quran/domain/quran_text_availability.dart';
import '../data/recording_repository.dart';
import '../domain/alignment.dart';
import '../domain/recording.dart';
import '../domain/span_index.dart';

/// The span index for Al-Fatiha and recording R3, or null when there is no
/// verified text, no verified local recording, or no alignment file.
final fatihaSpanIndexProvider = FutureProvider<SpanIndex?>((ref) async {
  final text = await ref.watch(surahTextProvider(1).future);
  final recording = await ref.watch(fatihaRecordingProvider.future);
  final alignment = await ref.watch(
    alignmentProvider(fatihaTafsirR3.alignmentAsset).future,
  );
  if (text is! QuranTextVerified ||
      recording is! RecordingReady ||
      alignment == null) {
    return null;
  }
  return SpanIndex.build(
    alignment: alignment,
    loadedRecordingSha256: recording.info.sha256,
    currentAyahSha256: {for (final a in text.surah.ayahs) a.number: a.sha256},
  );
});

/// What should be highlighted at [positionMs], given an index (if any).
AlignmentSpan? activeSpanAt(SpanIndex? index, int positionMs) =>
    index?.activeAt(positionMs);
