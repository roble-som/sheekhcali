import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

/// **Synthetic test fixture, not a real mapping.** Its times are invented for
/// tests and it is bound to a fake recording hash, so it can never match R3.
/// It is never bundled with the app.
const syntheticRecordingSha = 'synthetic-recording-sha-not-r3';

const syntheticRecording = RecordingInfo(
  id: 'synthetic',
  sha256: syntheticRecordingSha,
  bytes: 1,
  durationMs: 2912000,
  surah: 1,
  kind: RecordingKind.tafsir,
  rights: RecordingRights.testingOnly,
  id3Title: 'synthetic',
  id3Artist: 'synthetic',
  alignmentAsset: 'assets/content/alignments/al-fatiha-tafsir-r3.json',
);

Map<int, String> realAyahHashes() {
  final s = parseSurahAsset(
    File(BundledQuranTextRepository.assetPath(1)).readAsStringSync(),
  )!;
  return {for (final a in s.ayahs) a.number: a.sha256};
}

AlignmentSpan _v(String id, int a, int b, SpanKind k, List<int> ayahs) =>
    AlignmentSpan(
      id: id,
      startMs: a,
      endMs: b,
      kind: k,
      ayahs: ayahs,
      status: MappingStatus.verified,
      reviewer: 'TEST FIXTURE',
      reviewedAt: '2026-11-13',
    );

TafsirAlignment syntheticAlignment() => TafsirAlignment(
  recordingSha256: syntheticRecordingSha,
  recordingDurationMs: 2912000,
  surah: 1,
  textSourceSha256: 'synthetic',
  ayahSha256: realAyahHashes(),
  spans: [
    _v('intro', 0, 5000, SpanKind.intro, []),
    _v('r1', 5000, 15000, SpanKind.reading, [1]),
    _v('e1', 15000, 30000, SpanKind.explanation, [1]),
    _v('r2', 30000, 40000, SpanKind.reading, [2]),
    _v('e2', 40000, 60000, SpanKind.explanation, [2]),
    // 60000–65000: gap
    _v('e34', 65000, 80000, SpanKind.explanation, [3, 4]),
    const AlignmentSpan(
      id: 'draft5',
      startMs: 80000,
      endMs: 90000,
      kind: SpanKind.explanation,
      ayahs: [5],
      status: MappingStatus.draft,
      origin: 'asr-draft',
    ),
  ],
);

/// The rendered paragraph holding the Quran text.
RenderParagraph quranParagraph(WidgetTester tester) => tester.renderObject(
  find
      .descendant(
        of: find.byKey(const ValueKey('quran-text')),
        matching: find.byType(RichText),
      )
      .first, // ayah markers contain their own (inner) RichText widgets
);

/// All the text spans handed to the renderer, in order (excluding spaces and
/// widget spans), with their background colour.
List<(String, Color?)> renderedAyahSpans(WidgetTester tester) {
  final out = <(String, Color?)>[];
  quranParagraph(tester).text.visitChildren((span) {
    if (span is TextSpan && span.text != null && span.text!.trim().isNotEmpty) {
      out.add((span.text!, span.style?.backgroundColor));
    }
    return true;
  });
  return out;
}

/// Global centre of the first glyph run of [ayah] (for long press / tap).
Offset ayahCentre(WidgetTester tester, int ayah) {
  final paragraph = quranParagraph(tester);
  final raw = File(BundledQuranTextRepository.assetPath(1)).readAsStringSync();
  final ayahs = (jsonDecode(raw)['ayahs'] as List).cast<Map<String, dynamic>>();
  var start = 0;
  for (final a in ayahs) {
    final len = (a['text'] as String).length;
    if (a['number'] == ayah) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + len),
      );
      final box = boxes.first.toRect();
      return paragraph.localToGlobal(box.center);
    }
    start += len + 3; // text, space, marker placeholder, space
  }
  throw StateError('ayah $ayah not found');
}
