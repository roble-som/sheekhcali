// On-device test of "tap an ayah → hear the Sheikh's explanation of it".
//
// Run on an emulator or phone with the original recording installed
// (docs/review/AL_FATIHA_TAFSIR_REVIEW.md):
//   flutter test integration_test/fatiha_ayah_tafsir_test.dart -d <device>
//
// Uses the real app, the real just_audio/audio_service player and the real
// recording (hash-checked on the device).
//
// 1. ACCEPTANCE: the bundled production mapping. Every ayah with a reviewed
//    explanation must start playing at that span's start; every ayah without
//    one must say so and not move the audio.
// 2. MECHANICS (not acceptance): the AI-assisted CANDIDATE times from
//    docs/review/candidates/r3-candidates.json are injected in memory to
//    prove that a tap really seeks the real recording to the requested point
//    and plays, and that switching ayahs works. They are UNREVIEWED and never
//    used by the app.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sheekhcali/app/app.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/providers.dart';
import 'package:sheekhcali/features/tafsir_audio/application/fatiha_sync.dart';
import 'package:sheekhcali/features/tafsir_audio/application/tafsir_player.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UNREVIEWED candidate explanation spans (copied from
/// docs/review/candidates/r3-candidates.json). Mechanics test only.
const _candidateExplanations = <(String, int, int, List<int>)>[
  ('expl-1', 1558900, 1980000, [1]),
  ('expl-2', 1980000, 2267100, [2]),
  ('expl-3', 2267100, 2283100, [3]),
  ('expl-2-4', 2283100, 2361500, [2, 3, 4]),
  ('expl-4', 2361500, 2471800, [4]),
  ('expl-5', 2510800, 2740700, [5]),
  ('expl-6', 2740700, 2827100, [6]),
  ('expl-7', 2827100, 2912000, [7]),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object?>{};

  late List<String> ayahTexts;
  late Map<int, String> ayahHashes;

  setUpAll(() async {
    final raw = await rootBundle.loadString(
      'assets/quran/tanzil-uthmani-1.1/surah-001.json',
    );
    final ayahs = (jsonDecode(raw)['ayahs'] as List)
        .cast<Map<String, dynamic>>();
    ayahTexts = [for (final a in ayahs) a['text'] as String];
    ayahHashes = {
      for (final a in ayahs) a['number'] as int: a['sha256'] as String,
    };
  });

  tearDownAll(() => binding.reportData = report);

  Future<ProviderContainer> launch(
    WidgetTester tester, {
    List<Object> extra = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui.locale', 'en');
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialLocationProvider.overrideWithValue(AppRoutes.quran),
        ...extra.cast(),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SheekhCalinuurApp(),
      ),
    );
    // Hashing the 12.6 MB recording on the device takes a moment.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final status = container.read(fatihaRecordingProvider).value;
      if (status != null &&
          find.byKey(const ValueKey('quran-text')).evaluate().isNotEmpty) {
        expect(
          status,
          isA<RecordingReady>(),
          reason: 'install the recording first',
        );
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  RenderParagraph paragraph(WidgetTester tester) => tester.renderObject(
    find
        .descendant(
          of: find.byKey(const ValueKey('quran-text')),
          matching: find.byType(RichText),
        )
        .first,
  );

  Offset ayahCentre(WidgetTester tester, int ayah) {
    final p = paragraph(tester);
    var start = 0;
    for (var n = 1; n <= ayahTexts.length; n++) {
      final len = ayahTexts[n - 1].length;
      if (n == ayah) {
        final box = p
            .getBoxesForSelection(
              TextSelection(baseOffset: start, extentOffset: start + len),
            )
            .first
            .toRect();
        return p.localToGlobal(box.center);
      }
      start += len + 3;
    }
    throw StateError('no ayah $ayah');
  }

  List<int> highlighted(WidgetTester tester) {
    final out = <int>[];
    paragraph(tester).text.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.style?.backgroundColor != null) {
        final i = ayahTexts.indexOf(span.text!);
        if (i >= 0) out.add(i + 1);
      }
      return true;
    });
    return out;
  }

  /// Taps an ayah, first clearing any snackbar that could cover it.
  Future<void> tapAyah(WidgetTester tester, int ayah) async {
    ScaffoldMessenger.of(
      tester.element(find.byKey(const ValueKey('quran-text'))),
    ).removeCurrentSnackBar();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(ayahCentre(tester, ayah));
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    final end = DateTime.now().add(d);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'ACCEPTANCE: each ayah plays its reviewed explanation, or says it has none',
    (tester) async {
      final c = await launch(tester);
      final alignment = await c.read(
        alignmentProvider(fatihaTafsirR3.alignmentAsset).future,
      );
      final index = await c.read(fatihaSpanIndexProvider.future);
      final results = <String, Object?>{};
      for (var ayah = 1; ayah <= 7; ayah++) {
        final player = c.read(tafsirPlayerProvider);
        final before = player.current.position;
        final span = index?.explanationForAyah(ayah);
        await tapAyah(tester, ayah);
        await wait(tester, const Duration(seconds: 3));
        final after = player.current;
        if (span == null) {
          expect(
            find.text('Ayah $ayah has no reviewed explanation yet.'),
            findsWidgets,
            reason: 'ayah $ayah',
          );
          expect(
            after.position,
            before,
            reason: 'ayah $ayah must not move the audio',
          );
          results['ayah$ayah'] =
              'no reviewed explanation (message shown, audio not moved)';
        } else {
          final pos = after.position.inMilliseconds;
          expect(after.isPlaying, isTrue, reason: 'ayah $ayah playing');
          expect(
            pos,
            greaterThanOrEqualTo(span.startMs - 300),
            reason: 'ayah $ayah start',
          );
          expect(
            pos,
            lessThan(span.startMs + 6000),
            reason: 'ayah $ayah near start',
          );
          expect(
            highlighted(tester),
            containsAll(span.ayahs),
            reason: 'ayah $ayah highlight',
          );
          results['ayah$ayah'] =
              'reviewed span ${span.id} ${span.startMs}–${span.endMs} ms by ${span.reviewer}; '
              'position after 3 s: $pos ms; highlighted ${highlighted(tester)}';
        }
        // ignore: avoid_print
        print('ACCEPTANCE ayah $ayah: ${results['ayah$ayah']}');
      }
      report['acceptance'] = {
        'verifiedSpans': alignment?.verifiedCount ?? 0,
        'results': results,
      };
      await c.read(tafsirPlayerProvider).pause();
    },
  );

  testWidgets(
    'MECHANICS (UNREVIEWED candidates, not acceptance): taps seek the real recording',
    (tester) async {
      final candidate = TafsirAlignment(
        recordingSha256: fatihaTafsirR3.sha256,
        recordingDurationMs: fatihaTafsirR3.durationMs,
        surah: 1,
        textSourceSha256: 'candidate-test-only',
        ayahSha256: ayahHashes,
        spans: [
          for (final (id, a, b, ayahs) in _candidateExplanations)
            AlignmentSpan(
              id: id,
              startMs: a,
              endMs: b,
              kind: SpanKind.explanation,
              ayahs: ayahs,
              // Marked verified ONLY inside this test so the index will use it.
              status: MappingStatus.verified,
              reviewer: 'UNREVIEWED CANDIDATE (test only)',
              reviewedAt: 'n/a',
            ),
        ],
      );
      final c = await launch(
        tester,
        extra: [
          alignmentProvider.overrideWith((ref, asset) async => candidate),
        ],
      );
      final results = <String, Object?>{};
      // Taps in a mixed order, while playing, to test switching.
      for (final ayah in [1, 2, 3, 4, 5, 6, 7, 3, 1]) {
        final expected = _candidateExplanations.firstWhere(
          (e) => e.$4.length == 1 && e.$4.single == ayah,
        );
        final tappedAt = DateTime.now();
        await tapAyah(tester, ayah);
        // Wait (up to 15 s) for the real player to be playing at the
        // requested point. The first tap also opens the file.
        var p1 = c.read(tafsirPlayerProvider).current;
        while (DateTime.now().difference(tappedAt) <
            const Duration(seconds: 30)) {
          await tester.pump(const Duration(milliseconds: 100));
          p1 = c.read(tafsirPlayerProvider).current;
          final ms = p1.position.inMilliseconds;
          if (p1.phase == TafsirPhase.playing &&
              ms >= expected.$2 - 300 &&
              ms < expected.$2 + 3000) {
            break;
          }
        }
        final latency = DateTime.now().difference(tappedAt).inMilliseconds;
        final trace = <String>[];
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          final st = c.read(tafsirPlayerProvider).current;
          trace.add('${st.phase.name}@${st.position.inMilliseconds}');
        }
        // ignore: avoid_print
        print('TRACE ayah $ayah: ${trace.join(' ')}');
        // Read after 2 s, this comes from just_audio's own position stream,
        // not from the seek request: it proves where the audio really is.
        final p2 = c.read(tafsirPlayerProvider).current;
        final hl = highlighted(tester);
        expect(p1.isPlaying, isTrue, reason: 'ayah $ayah playing');
        expect(p2.isPlaying, isTrue, reason: 'ayah $ayah still playing');
        expect(
          p2.position.inMilliseconds,
          inInclusiveRange(expected.$2 + 1000, expected.$2 + 6000),
          reason: 'ayah $ayah: real position 2 s after the start',
        );
        expect(hl, contains(ayah), reason: 'ayah $ayah highlighted');
        final line =
            'tap ayah $ayah → requested ${expected.$2} ms (${expected.$1}); '
            'playing after $latency ms; real position 2 s later: '
            '${p2.position.inMilliseconds} ms; highlighted $hl';
        results['ayah$ayah@${results.length}'] = line;
        // ignore: avoid_print
        print('MECHANICS $line');
      }
      report['mechanicsUnreviewedCandidates'] = results;
      await c.read(tafsirPlayerProvider).pause();
    },
  );
}
