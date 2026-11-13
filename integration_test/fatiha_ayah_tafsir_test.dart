// On-device test of "tap an ayah → hear the Sheikh's explanation of it".
//
// Run through tool/device/fatiha_audio_check.sh, which installs the original
// recording (hash-checked), records what the emulator actually outputs, and
// checks that each tap was audible and came from the right place in the
// recording. Can also run alone:
//   flutter test integration_test/fatiha_ayah_tafsir_test.dart -d <device>
//
// Uses the real app, the real just_audio/audio_service player, the real
// recording and the real bundled mapping and candidates. Nothing is injected
// except, in the acceptance test, turning review mode off.
//
// 1. ACCEPTANCE (reviewed spans only, as in production): every ayah with a
//    reviewed explanation must play it from its start; every ayah without one
//    must say so and not move the audio.
// 2. REVIEW MODE (debug builds): the bundled UNREVIEWED AI-assisted candidates
//    play for ayahs with no reviewed span, labelled as unreviewed. Evidence
//    lines (EVIDENCE {...}) feed the host-side audibility check.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sheekhcali/app/app.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/providers.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';
import 'package:sheekhcali/features/quran/presentation/widgets/surah_text_view.dart';
import 'package:sheekhcali/features/tafsir_audio/application/fatiha_sync.dart';
import 'package:sheekhcali/features/tafsir_audio/application/tafsir_player.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio to let play after each tap (the host check listens to this stretch).
const _listen = Duration(seconds: 6);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> launch(
    WidgetTester tester, {
    required bool reviewMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui.locale', 'en');
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialLocationProvider.overrideWithValue(AppRoutes.quran),
        if (!reviewMode) reviewModeProvider.overrideWithValue(false),
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
          reason: 'install the recording first (tool/device/install_r3.sh)',
        );
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  Future<SurahText> fatiha(ProviderContainer c) async =>
      (await c.read(surahTextProvider(1).future) as QuranTextVerified).surah;

  RenderParagraph paragraph(WidgetTester tester) => tester.renderObject(
    find
        .descendant(
          of: find.byKey(const ValueKey('quran-text')),
          matching: find.byType(RichText),
        )
        .first,
  );

  Offset ayahCentre(WidgetTester tester, SurahText surah, int ayah) {
    final p = paragraph(tester);
    final slot = AyahLayout(surah).slots.firstWhere((s) => s.number == ayah);
    final box = p
        .getBoxesForSelection(
          TextSelection(
            baseOffset: slot.text.start,
            extentOffset: slot.text.end,
          ),
        )
        .first
        .toRect();
    return p.localToGlobal(box.center);
  }

  List<int> highlighted(WidgetTester tester, SurahText surah) {
    final out = <int>[];
    paragraph(tester).text.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.style?.backgroundColor != null) {
        final i = surah.ayahs.indexWhere((a) => a.text == span.text);
        if (i >= 0) out.add(i + 1);
      }
      return true;
    });
    return out;
  }

  String syncLine(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('tafsir-sync'))).data!;

  /// Taps an ayah, first clearing any snackbar that could cover it.
  Future<void> tapAyah(WidgetTester tester, SurahText surah, int ayah) async {
    ScaffoldMessenger.of(
      tester.element(find.byKey(const ValueKey('quran-text'))),
    ).removeCurrentSnackBar();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(ayahCentre(tester, surah, ayah));
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    final end = DateTime.now().add(d);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void evidence(Map<String, Object?> e) {
    // ignore: avoid_print
    print('EVIDENCE ${jsonEncode(e)}');
  }

  testWidgets('ACCEPTANCE: reviewed explanations only (production rule)', (
    tester,
  ) async {
    final c = await launch(tester, reviewMode: false);
    final surah = await fatiha(c);
    final index = await c.read(fatihaSpanIndexProvider.future);
    for (var ayah = 1; ayah <= 7; ayah++) {
      final player = c.read(tafsirPlayerProvider);
      final before = player.current.position;
      final span = index?.explanationForAyah(ayah);
      await tapAyah(tester, surah, ayah);
      await wait(tester, const Duration(seconds: 3));
      final after = player.current;
      if (span == null) {
        expect(
          find.text('Ayah $ayah has no reviewed explanation yet.'),
          findsWidgets,
          reason: 'ayah $ayah',
        );
        expect(after.position, before, reason: 'ayah $ayah: no seek');
        evidence({
          'test': 'acceptance',
          'ayah': ayah,
          'reviewedSegment': null,
          'result': 'message shown, audio not moved',
        });
      } else {
        final pos = after.position.inMilliseconds;
        expect(after.phase, TafsirPhase.playing, reason: 'ayah $ayah');
        expect(pos, inInclusiveRange(span.startMs - 300, span.startMs + 6000));
        expect(highlighted(tester, surah), containsAll(span.ayahs));
        evidence({
          'test': 'acceptance',
          'ayah': ayah,
          'reviewedSegment': span.id,
          'startMs': span.startMs,
          'endMs': span.endMs,
          'reviewer': span.reviewer,
          'positionMs': pos,
        });
      }
    }
    await c.read(tafsirPlayerProvider).pause();
  });

  testWidgets("REVIEW MODE: each tap plays that ayah's segment", (
    tester,
  ) async {
    final c = await launch(tester, reviewMode: true);
    final surah = await fatiha(c);
    final index = await c.read(fatihaSpanIndexProvider.future);
    final candidates = await c.read(fatihaCandidatesProvider.future);
    expect(candidates, isNotNull, reason: 'bundled candidates must load');

    // 1–7 in order, then switching back while audio plays.
    for (final ayah in [1, 2, 3, 4, 5, 6, 7, 3, 1]) {
      final reviewed = index?.explanationForAyah(ayah);
      final candidate = candidates!.explanationForAyah(ayah)!;
      final startMs = reviewed?.startMs ?? candidate.startMs;
      final endMs = reviewed?.endMs ?? candidate.endMs;
      final id = reviewed?.id ?? candidate.id;

      final tappedAt = DateTime.now();
      await tapAyah(tester, surah, ayah);
      var state = c.read(tafsirPlayerProvider).current;
      while (DateTime.now().difference(tappedAt) <
          const Duration(seconds: 30)) {
        await tester.pump(const Duration(milliseconds: 50));
        state = c.read(tafsirPlayerProvider).current;
        final ms = state.position.inMilliseconds;
        if (state.phase == TafsirPhase.playing &&
            ms >= startMs - 300 &&
            ms < startMs + 3000) {
          break;
        }
      }
      final playingAt = DateTime.now();
      final startPos = state.position.inMilliseconds;
      expect(state.phase, TafsirPhase.playing, reason: 'ayah $ayah playing');
      final line = syncLine(tester);
      final hl = highlighted(tester, surah);
      await wait(tester, _listen);
      final later = c.read(tafsirPlayerProvider).current;
      final laterPos = later.position.inMilliseconds;
      evidence({
        'test': 'review',
        'ayah': ayah,
        'segment': id,
        'reviewed': reviewed != null,
        'confidence': reviewed == null ? candidate.confidence : null,
        'segmentStartMs': startMs,
        'segmentEndMs': endMs,
        'msToPlaying': playingAt.difference(tappedAt).inMilliseconds,
        'playingAtEpochMs': playingAt.millisecondsSinceEpoch,
        'positionAtPlayingMs': startPos,
        'positionAfterListenMs': laterPos,
        'listenMs': _listen.inMilliseconds,
        'phaseAfterListen': later.phase.name,
        'highlighted': hl,
        'playerLine': line,
      });
      final segmentMs = endMs - startMs;
      if (segmentMs > _listen.inMilliseconds + 1000) {
        expect(later.phase, TafsirPhase.playing, reason: 'ayah $ayah still');
        // just_audio's own position, read seconds later: where the audio is.
        expect(
          laterPos,
          inInclusiveRange(
            startMs + _listen.inMilliseconds - 1500,
            startMs + _listen.inMilliseconds + 3000,
          ),
          reason: 'ayah $ayah: real position ${_listen.inSeconds} s later',
        );
      }
      expect(hl, contains(ayah), reason: 'ayah $ayah highlighted');
      if (reviewed == null) {
        expect(line, startsWith('Unreviewed AI candidate · Ayah'));
      }
    }

    // Stop at the end: ayah 3's segment is short; let it run out.
    final c3 = candidates!.explanationForAyah(3)!;
    final reviewed3 = index?.explanationForAyah(3);
    final start3 = reviewed3?.startMs ?? c3.startMs;
    final end3 = reviewed3?.endMs ?? c3.endMs;
    await tapAyah(tester, surah, 3);
    final limit = DateTime.now().add(
      Duration(milliseconds: end3 - start3 + 15000),
    );
    await wait(tester, const Duration(seconds: 3));
    var s = c.read(tafsirPlayerProvider).current;
    while (DateTime.now().isBefore(limit)) {
      await tester.pump(const Duration(milliseconds: 100));
      s = c.read(tafsirPlayerProvider).current;
      if (s.phase == TafsirPhase.paused) break;
    }
    evidence({
      'test': 'stop-at-end',
      'ayah': 3,
      'segmentEndMs': end3,
      'phase': s.phase.name,
      'positionMs': s.position.inMilliseconds,
      'playerLine': syncLine(tester),
      'stoppedAtEpochMs': DateTime.now().millisecondsSinceEpoch,
    });
    expect(s.phase, TafsirPhase.paused, reason: 'stops at the segment end');
    expect(
      s.position.inMilliseconds,
      inInclusiveRange(end3 - 200, end3 + 1500),
    );
    // Quiet after the stop: the host check uses this as its silence sample.
    final quietFrom = DateTime.now().millisecondsSinceEpoch + 500;
    await wait(tester, const Duration(seconds: 4));
    evidence({
      'test': 'silence',
      'fromEpochMs': quietFrom,
      'toEpochMs': quietFrom + 3000,
    });
  });
}
