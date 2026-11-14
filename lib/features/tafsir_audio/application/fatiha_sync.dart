import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/build_flags.dart';
import '../../quran/data/quran_text_repository.dart';
import '../../quran/domain/quran_text_availability.dart';
import '../data/recording_repository.dart';
import '../domain/alignment.dart';
import '../domain/candidates.dart';
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

/// Whether unreviewed AI-assisted candidate segments may be played, clearly
/// labelled, when an ayah has no reviewed segment yet (P-25). Debug and
/// testing builds only: other builds can't play the testing-only recording
/// at all (C-26), and production uses reviewed spans only.
final reviewModeProvider = Provider<bool>(
  (ref) => kDebugMode || kTestingAudioBuild,
);

/// Bundled candidates file for R3 (generated from
/// docs/review/candidates/r3-candidates.json by
/// tool/review/build_review_page.dart).
const fatihaCandidatesAsset =
    'assets/content/alignments/al-fatiha-tafsir-r3.candidates.json';

/// The candidate segments for Al-Fatiha and R3, or null outside review mode,
/// without a verified local recording or text, or if the candidates were made
/// for different bytes.
final fatihaCandidatesProvider = FutureProvider<CandidateSet?>((ref) async {
  if (!ref.watch(reviewModeProvider)) return null;
  final text = await ref.watch(surahTextProvider(1).future);
  final recording = await ref.watch(fatihaRecordingProvider.future);
  if (text is! QuranTextVerified || recording is! RecordingReady) return null;
  // The candidates were made for R3's exact bytes and nothing else.
  if (recording.info.sha256 != fatihaTafsirR3.sha256) return null;
  try {
    final raw = await rootBundle.loadString(fatihaCandidatesAsset);
    final set = CandidateSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final usable = set.isUsableFor(
      recordingSha256: recording.info.sha256,
      currentAyahSha256: {for (final a in text.surah.ayahs) a.number: a.sha256},
    );
    return usable ? set : null;
  } on Object {
    return null;
  }
});
