import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';
import 'package:sheekhcali/features/quran/presentation/quran_reader_screen.dart';
import 'package:sheekhcali/features/tafsir_audio/application/tafsir_player.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

import '../support/fakes.dart';
import '../support/synthetic_alignment.dart';
import '../support/test_app.dart';

class _UnavailableRepo implements QuranTextRepository {
  @override
  Future<QuranTextAvailability> surah(int number) async =>
      const QuranTextUnavailable(reasons: ['integrity']);
}

void main() {
  final stored = parseSurahAsset(
    File(BundledQuranTextRepository.assetPath(1)).readAsStringSync(),
  )!.ayahs.map((a) => a.text).toList();

  group('verified Al-Fatiha text', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('$locale: the renderer receives the stored text exactly', (
        tester,
      ) async {
        await pumpApp(tester, locale: locale, location: AppRoutes.quran);
        final rendered = renderedAyahSpans(tester).map((e) => e.$1).toList();
        expect(rendered, stored); // 7 ayahs, in order, byte for byte
        expect(find.text('سورة الفاتحة'), findsOneWidget);
        // No placeholder preview when verified text is shown.
        expect(find.text('Layout preview · not Quran text'), findsNothing);
        expect(find.text('معاينة التخطيط · ليس نص القرآن'), findsNothing);
      });
    }

    testWidgets('Quran text is RTL and set in the Quran font', (tester) async {
      await pumpApp(tester, location: AppRoutes.quran);
      final rich = tester.widget<RichText>(
        find
            .descendant(
              of: find.byKey(const ValueKey('quran-text')),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(rich.textDirection, TextDirection.rtl);
      // Text.rich wraps our span in one carrying the default style.
      final quranSpan = (rich.text as TextSpan).children!.first as TextSpan;
      expect(quranSpan.style!.fontFamily, 'AmiriQuranText');
      expect(quranSpan.style!.fontSize, greaterThanOrEqualTo(20));
    });

    testWidgets('ayah markers number 1–7 in Arabic-Indic digits', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.quran);
      // The numbers are part of the Quran paragraph (see
      // test/quran/ayah_numbering_test.dart for where each one is drawn).
      final text = quranParagraph(tester).text
          .toPlainText(includeSemanticsLabels: false);
      for (final d in ['١', '٢', '٣', '٤', '٥', '٦', '٧']) {
        expect(RegExp('\u2007$d\u2007').allMatches(text).length, 1, reason: d);
      }
    });

    testWidgets('meta line and source attribution (Tanzil terms)', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.quran);
      expect(find.text('Makki · 7 ayahs'), findsOneWidget);
      expect(
        find.text('Quran text: Tanzil Uthmani 1.1 · tanzil.net'),
        findsOneWidget,
      );
      expect(find.text('Reviewer check pending'), findsOneWidget);
      final source = find.text('Quran text: Tanzil Uthmani 1.1 · tanzil.net');
      await tester.ensureVisible(source);
      await tester.pumpAndSettle();
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(find.byType(QuranSourceDialog), findsOneWidget);
      expect(find.text('https://tanzil.net/'), findsOneWidget);
      expect(find.textContaining('The basmala is ayah 1'), findsOneWidget);
    });

    testWidgets(
      'fails closed: unverifiable text shows only the labelled preview',
      (tester) async {
        await pumpApp(
          tester,
          location: AppRoutes.quran,
          quranText: _UnavailableRepo(),
        );
        expect(find.text('Layout preview · not Quran text'), findsOneWidget);
        expect(find.byKey(const ValueKey('quran-text')), findsNothing);
      },
    );

    testWidgets(
      'long press ayah 6 → Copy puts the exact stored text on the clipboard',
      (tester) async {
        String? clipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        await pumpApp(tester, location: AppRoutes.quran);
        await tester.longPressAt(ayahCentre(tester, 6));
        await tester.pumpAndSettle();
        // While the sheet is open, ayah 6 is marked as selected.
        final marked = renderedAyahSpans(tester)
            .where((e) => e.$2 != null)
            .toList();
        expect(marked.map((e) => e.$1), [stored[5]]);
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(clipboard, '${stored[5]}\nAl-Faatiha 1:6');
        expect(find.text('Copied Al-Faatiha 1:6'), findsOneWidget);
      },
    );

    testWidgets('Play Tafsir explains when the recording is not installed', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.quran);
      await tester.longPressAt(ayahCentre(tester, 2));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Play Tafsir', findRichText: true));
      await tester.pumpAndSettle();
      expect(
        find.text("The Sheikh's recording isn't available on this device."),
        findsOneWidget,
      );
    });

    testWidgets('tapping outside the text toggles the reader chrome', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.quran);
      await tester.tap(find.text('سورة الفاتحة'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('More options'), findsNothing);
      await tester.tap(find.text('سورة الفاتحة'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('More options'), findsOneWidget);
    });

    testWidgets('Arabic UI: same Quran text, mirrored chrome', (tester) async {
      await pumpApp(tester, locale: 'ar', location: AppRoutes.quran);
      expect(renderedAyahSpans(tester).map((e) => e.$1).toList(), stored);
      expect(find.text('مكية · ٧ آيات'), findsOneWidget);
      final menu = tester.getCenter(find.byTooltip('فتح قائمة التنقل'));
      expect(menu.dx, greaterThan(384 / 2));
    });
  });

  group('Tafsir player', () {
    testWidgets('not installed: honest notice, no controls', (tester) async {
      await pumpApp(tester, location: AppRoutes.quran);
      expect(
        find.text(
          "The Sheikh's Tafsir recording isn't installed on this device.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('tafsir-play')), findsNothing);
    });

    testWidgets('web build: says the recording plays in the phone app only', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingPlatformUnsupported(),
      );
      const msg =
          "The Sheikh's recording plays only in the Android and iOS app. "
          'It is a testing-only file and is not part of the web version.';
      expect(find.text(msg), findsOneWidget);
      await tester.tapAt(ayahCentre(tester, 2));
      await tester.pumpAndSettle();
      expect(find.text(msg), findsNWidgets(2)); // bar + tap message
      expect(find.byKey(const ValueKey('tafsir-play')), findsNothing);
    });

    testWidgets('checksum mismatch: refuses to play', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingChecksumMismatch('deadbeef'),
      );
      expect(
        find.text(
          "This file isn't the original recording, so it won't be played.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('tafsir-play')), findsNothing);
    });

    testWidgets('release builds: no player at all (testing-only rights)', (
      tester,
    ) async {
      final repo = LocalRecordingRepository(allowTestingOnly: false);
      expect(await repo.locate(fatihaTafsirR3), isA<RecordingNotPermitted>());
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingNotPermitted(),
      );
      expect(find.byKey(const ValueKey('tafsir-play')), findsNothing);
      expect(find.textContaining('recording isn'), findsNothing);
    });

    testWidgets('ready: labelled as Tafsir, plays, pauses, shows times', (
      tester,
    ) async {
      final player = FakeTafsirPlayer();
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingReady('/fake/r3.mp3', fatihaTafsirR3),
        player: player,
      );
      expect(find.text("Sheikh's Tafsir · original recording"), findsOneWidget);
      expect(find.text('Explanation, not Quran recitation'), findsOneWidget);
      expect(find.text('Testing only · not for distribution'), findsOneWidget);
      expect(find.text('48:32'), findsOneWidget);
      // R3's real alignment has no reviewed spans yet (C-27).
      expect(
        find.text('Ayah highlighting: waiting for review'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      expect(player.commands, ['load:/fake/r3.mp3', 'play']);
      expect(find.byTooltip('Pause'), findsOneWidget);

      player.setPosition(const Duration(minutes: 12, seconds: 4));
      await tester.pump();
      await tester.pump();
      expect(find.text('12:04'), findsOneWidget);
      // No verified spans: nothing is highlighted while R3 plays.
      expect(renderedAyahSpans(tester).where((e) => e.$2 != null), isEmpty);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(player.commands.last, 'pause');
    });

    testWidgets('load error shows the error state and allows retry', (
      tester,
    ) async {
      final player = FakeTafsirPlayer()..failNextLoad = true;
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingReady('/fake/r3.mp3', fatihaTafsirR3),
        player: player,
      );
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      expect(find.text("The recording couldn't be played."), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      expect(player.commands.where((c) => c.startsWith('load')).length, 2);
    });

    testWidgets('completed state offers replay from the start', (tester) async {
      final player = FakeTafsirPlayer();
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingReady('/fake/r3.mp3', fatihaTafsirR3),
        player: player,
      );
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      player.emit(player.current.copyWith(phase: TafsirPhase.completed));
      await tester.pump();
      await tester.pump();
      expect(find.byTooltip('Play again'), findsOneWidget);
    });
  });

  group('verified-span highlighting (synthetic test mapping)', () {
    Future<FakeTafsirPlayer> start(
      WidgetTester tester, {
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
        ],
      );
      await tester.tap(find.byKey(const ValueKey('tafsir-play')));
      await tester.pumpAndSettle();
      return player;
    }

    List<String> highlighted(WidgetTester tester) =>
        renderedAyahSpans(tester)
            .where((e) => e.$2 != null)
            .map((e) => e.$1)
            .toList();

    testWidgets('highlight follows the playing span, and gaps clear it', (
      tester,
    ) async {
      final player = await start(tester);
      Future<void> at(int ms) async {
        player.setPosition(Duration(milliseconds: ms));
        await tester.pump();
        await tester.pump();
      }

      await at(1000); // intro: nothing
      expect(highlighted(tester), isEmpty);
      expect(find.text('Introduction · 0:00–0:05'), findsOneWidget);
      await at(6000); // reading ayah 1
      expect(highlighted(tester), [stored[0]]);
      expect(find.text('Ayah 1 · recitation · 0:05–0:15'), findsOneWidget);
      await at(20000); // explaining ayah 1
      expect(highlighted(tester), [stored[0]]);
      expect(find.text('Ayah 1 · explaining · 0:15–0:30'), findsOneWidget);
      await at(45000); // explaining ayah 2
      expect(highlighted(tester), [stored[1]]);
      await at(62000); // gap
      expect(highlighted(tester), isEmpty);
      expect(find.text('No reviewed passage at this point'), findsOneWidget);
      await at(70000); // one span explaining ayahs 3 and 4 together
      expect(highlighted(tester), [stored[2], stored[3]]);
      await at(85000); // DRAFT span for ayah 5: never highlights
      expect(highlighted(tester), isEmpty);
    });

    testWidgets(
      'seeking backwards and forwards never leaves a stale highlight',
      (tester) async {
        final player = await start(tester);
        for (final (ms, expected) in [
          (70000, [stored[2], stored[3]]),
          (6000, [stored[0]]),
          (62000, <String>[]),
          (35000, [stored[1]]),
          (2911000, <String>[]),
        ]) {
          await player.seek(Duration(milliseconds: ms));
          await tester.pump();
          expect(highlighted(tester), expected, reason: 'after seek to $ms');
        }
      },
    );

    testWidgets(
      'tapping each ayah plays its own explanation (not recitation)',
      (tester) async {
        final player = await start(tester);
        Future<void> tap(int ayah) async {
          await tester.tapAt(ayahCentre(tester, ayah));
          await tester.pump();
          await tester.pump();
        }

        await tap(1);
        expect(player.commands, containsAllInOrder(['seek:15000', 'play']));
        expect(highlighted(tester), [stored[0]]);
        expect(find.text('Ayah 1 · explaining · 0:15–0:30'), findsOneWidget);

        // Switching while playing jumps to the other ayah's explanation.
        await tap(2);
        expect(player.commands.last, 'play');
        expect(player.commands, contains('seek:40000'));
        expect(highlighted(tester), [stored[1]]);

        // Ayah 4 is explained together with ayah 3: same shared segment.
        await tap(4);
        expect(player.commands, contains('seek:65000'));
        expect(highlighted(tester), [stored[2], stored[3]]);
      },
    );

    testWidgets(
      'an ayah without a reviewed explanation says so and does not seek',
      (tester) async {
        final player = await start(tester);
        final before = player.commands.length;
        await tester.tapAt(ayahCentre(tester, 7));
        await tester.pumpAndSettle();
        expect(player.commands.length, before);
        expect(
          find.text('Ayah 7 has no reviewed explanation yet.'),
          findsOneWidget,
        );
        expect(
          find.text('Ayah 7: no reviewed explanation yet'),
          findsOneWidget,
        );
        // Ayah 5 has only a DRAFT span: it is not offered either.
        await tester.tapAt(ayahCentre(tester, 5));
        await tester.pumpAndSettle();
        expect(player.commands.length, before);
      },
    );

    testWidgets('Arabic UI: same highlighting, Arabic sync line', (
      tester,
    ) async {
      final player = await start(tester, locale: 'ar');
      player.setPosition(const Duration(milliseconds: 45000));
      await tester.pump();
      await tester.pump();
      expect(highlighted(tester), [stored[1]]);
      expect(find.text('الآية ٢ · شرح · 0:40–1:00'), findsOneWidget);
    });

    testWidgets('the real R3 mapping is not used for a different recording', (
      tester,
    ) async {
      // Synthetic recording + the real (bundled) alignment: hashes differ, so
      // the mapping is switched off rather than applied to the wrong audio.
      final player = FakeTafsirPlayer();
      await pumpApp(
        tester,
        location: AppRoutes.quran,
        recording: const RecordingReady('/fake/other.mp3', syntheticRecording),
        player: player,
      );
      expect(
        find.text('The mapping belongs to a different recording'),
        findsOneWidget,
      );
    });
  });
}
