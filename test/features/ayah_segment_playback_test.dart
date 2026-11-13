import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/tafsir_audio/application/fatiha_sync.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/alignment.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/candidates.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

import '../support/fakes.dart';
import '../support/synthetic_alignment.dart';
import '../support/test_app.dart';

/// Tap an ayah → its segment plays and stops at the segment's end.
///
/// SYNTHETIC data only (fake player, synthetic recording, synthetic reviewed
/// spans and synthetic candidates): this proves the app's logic. The real
/// recording is exercised on a device by
/// integration_test/fatiha_ayah_tafsir_test.dart.
void main() {
  setUpAll(loadAppFonts);

  // Synthetic candidates: ayah 2 also has a (worse) candidate, ayah 7 has
  // only a candidate, ayahs 5–6 have a shared candidate.
  const candidates = CandidateSet(
    recordingSha256: 'synthetic-recording-sha-not-r3',
    recordingDurationMs: 120000,
    ayahSha256: {},
    spans: [
      CandidateSpan(
        id: 'c2',
        kind: SpanKind.explanation,
        ayahs: [2],
        startMs: 99000,
        endMs: 100000,
        confidence: 'low',
      ),
      CandidateSpan(
        id: 'c56',
        kind: SpanKind.explanation,
        ayahs: [5, 6],
        startMs: 92000,
        endMs: 96000,
        confidence: 'medium',
      ),
      CandidateSpan(
        id: 'r7',
        kind: SpanKind.reading,
        ayahs: [7],
        startMs: 1000,
        endMs: 2000,
        confidence: 'high',
      ),
      CandidateSpan(
        id: 'c7',
        kind: SpanKind.explanation,
        ayahs: [7],
        startMs: 100000,
        endMs: 110000,
        confidence: 'low',
      ),
    ],
  );

  Future<FakeTafsirPlayer> start(
    WidgetTester tester, {
    bool reviewMode = true,
    String locale = 'en',
  }) async {
    final player = FakeTafsirPlayer();
    await pumpApp(
      tester,
      locale: locale,
      location: AppRoutes.quran,
      recording: const RecordingReady(
        '/fake/synthetic.mp3',
        syntheticRecording,
      ),
      player: player,
      overrides: [
        alignmentProvider.overrideWith(
          (ref, asset) async => syntheticAlignment(),
        ),
        reviewModeProvider.overrideWithValue(reviewMode),
        fatihaCandidatesProvider.overrideWith(
          (ref) async => reviewMode ? candidates : null,
        ),
      ],
    );
    await tester.pumpAndSettle();
    return player;
  }

  String syncLine(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('tafsir-sync'))).data!;

  Future<void> tap(WidgetTester tester, int ayah) async {
    await tester.tapAt(ayahCentre(tester, ayah));
    await tester.pumpAndSettle();
  }

  testWidgets('an ayah with only a candidate plays it, labelled UNREVIEWED', (
    tester,
  ) async {
    final player = await start(tester);
    await tap(tester, 7);
    expect(player.commands, containsAllInOrder(['seek:100000', 'play']));
    expect(
      syncLine(tester),
      'Unreviewed AI candidate · Ayah 7 · 1:40–1:50 · low confidence · '
      'not verified',
    );
    // Never the recitation candidate (r7 at 0:01).
    expect(player.commands, isNot(contains('seek:1000')));
  });

  testWidgets('a reviewed explanation always wins over a candidate', (
    tester,
  ) async {
    final player = await start(tester);
    await tap(tester, 2);
    expect(player.commands, contains('seek:40000'));
    expect(player.commands, isNot(contains('seek:99000')));
    player.setPosition(const Duration(milliseconds: 41000));
    await tester.pump();
    await tester.pump();
    expect(syncLine(tester), 'Ayah 2 · explaining · 0:40–1:00');
  });

  testWidgets('a shared candidate explains both ayahs', (tester) async {
    final player = await start(tester);
    await tap(tester, 6);
    expect(player.commands, contains('seek:92000'));
    expect(syncLine(tester), contains('Ayah 5–6'));
  });

  testWidgets('switching ayahs while playing switches segments', (
    tester,
  ) async {
    final player = await start(tester);
    await tap(tester, 7);
    await tap(tester, 1);
    await tap(tester, 6);
    final seeks = player.commands.where((c) => c.startsWith('seek:'));
    expect(seeks, ['seek:100000', 'seek:15000', 'seek:92000']);
  });

  testWidgets('playback stops at the end of the tapped segment', (
    tester,
  ) async {
    final player = await start(tester);
    await tap(tester, 7);
    player.setPosition(const Duration(milliseconds: 109000));
    await tester.pump();
    expect(player.commands.last, 'play');
    player.setPosition(const Duration(milliseconds: 110100));
    await tester.pump();
    await tester.pump();
    expect(player.commands.last, 'pause');
    expect(
      syncLine(tester),
      'Ayah 7: end of this segment · tap the ayah to hear it again',
    );
  });

  testWidgets('outside review mode, a candidate is never played', (
    tester,
  ) async {
    final player = await start(tester, reviewMode: false);
    final before = player.commands.length;
    await tap(tester, 7);
    expect(player.commands.length, before);
    expect(
      find.text('Ayah 7 has no reviewed explanation yet.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic UI: unreviewed label in Arabic', (tester) async {
    await start(tester, locale: 'ar');
    await tap(tester, 7);
    expect(syncLine(tester), contains('غير مُراجَع'));
    expect(syncLine(tester), contains('الآية ٧'));
  });
}
