import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/application/fatiha_sync.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/candidates.dart';

/// The real R3 candidates bundled for review mode (UNREVIEWED).
void main() {
  final set = CandidateSet.fromJson(
    jsonDecode(File(fatihaCandidatesAsset).readAsStringSync())
        as Map<String, dynamic>,
  );
  final review = jsonDecode(
    File('docs/review/candidates/r3-candidates.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final surah = parseSurahAsset(
    File(BundledQuranTextRepository.assetPath(1)).readAsStringSync(),
  )!;

  test('bound to R3 and the current Al-Fatiha text', () {
    expect(set.recordingSha256, fatihaTafsirR3.sha256);
    expect(set.recordingDurationMs, fatihaTafsirR3.durationMs);
    expect(
      set.isUsableFor(
        recordingSha256: fatihaTafsirR3.sha256,
        currentAyahSha256: {for (final a in surah.ayahs) a.number: a.sha256},
      ),
      isTrue,
    );
    expect(
      set.isUsableFor(
        recordingSha256: 'another-recording',
        currentAyahSha256: {for (final a in surah.ayahs) a.number: a.sha256},
      ),
      isFalse,
    );
  });

  test('the app copy has exactly the review copy timings (regenerate with '
      'tool/review/build_review_page.dart)', () {
    final spans = (review['spans'] as List).cast<Map<String, dynamic>>();
    expect(set.spans.length, spans.length);
    for (var i = 0; i < spans.length; i++) {
      expect(set.spans[i].id, spans[i]['id']);
      expect(set.spans[i].startMs, spans[i]['startMs']);
      expect(set.spans[i].endMs, spans[i]['endMs']);
      expect(set.spans[i].ayahs, spans[i]['ayahs']);
      expect(set.spans[i].kind.name, spans[i]['kind']);
      expect(set.spans[i].confidence, spans[i]['confidence']);
    }
  });

  test('none of the candidates is marked verified or carries a reviewer', () {
    final raw = File(fatihaCandidatesAsset).readAsStringSync();
    expect(raw, isNot(contains('"verified"')));
    expect(raw, isNot(contains('reviewer')));
    expect(raw, contains('UNREVIEWED'));
  });

  test(
    'each ayah resolves to an explanation candidate, never a recitation',
    () {
      final resolved = {
        for (var n = 1; n <= 7; n++) n: set.explanationForAyah(n),
      };
      for (final e in resolved.entries) {
        expect(e.value, isNotNull, reason: 'ayah ${e.key}');
        expect(e.value!.kind, SpanKind.explanation);
        expect(e.value!.ayahs, contains(e.key));
        // The opening recitation is 0:25–0:58; explanations start after 25:00.
        expect(e.value!.startMs, greaterThan(25 * 60 * 1000));
      }
      expect(
        {for (final e in resolved.entries) e.key: e.value!.id},
        {
          1: 'expl-1',
          2: 'expl-2',
          3: 'expl-3',
          4: 'expl-4',
          5: 'expl-5',
          6: 'expl-6',
          7: 'expl-7',
        },
      );
    },
  );
}
