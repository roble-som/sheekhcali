import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';

import '../support/rendered_numbering.dart';
import '../support/test_app.dart';

/// Every surah, as rendered in the whole-surah layout: each ayah number is
/// drawn right after its own ayah (QURAN_AND_AUDIO_ACCURACY §3: numbering and
/// display order). The page layout is checked in all_pages_test.dart.
void main() {
  setUpAll(loadAppFonts);

  for (final (from, to) in [(1, 20), (21, 50), (51, 80), (81, 114)]) {
    testWidgets('surahs $from–$to: every number follows its ayah', (
      tester,
    ) async {
      final problems = <String>[];
      for (var n = from; n <= to; n++) {
        final surah = parseSurahAsset(
          File(BundledQuranTextRepository.assetPath(n)).readAsStringSync(),
        )!;
        await pumpApp(
          tester,
          location: AppRoutes.quranAt(n),
          physicalSize: const Size(384 * referenceDpr, 832 * referenceDpr),
          extraPrefs: const {'quran.layout': 'surah'},
        );
        problems.addAll(checkRenderedNumbering(tester, surah));
        // The basmala heading is shown exactly where the source has one.
        expect(
          find.byKey(const ValueKey('basmala-heading')).evaluate().length,
          surah.basmalaHeading == null ? 0 : 1,
          reason: 'surah $n',
        );
      }
      expect(problems, isEmpty);
    });
  }
}
