import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/app/router.dart';
import 'package:sheekhcali/core/l10n/localized_digits.dart';
import 'package:sheekhcali/features/quran/data/quran_text_repository.dart';

import '../support/synthetic_alignment.dart';
import '../support/test_app.dart';

/// Ayah numbering as the reader *shows* it (not only as the data stores it).
///
/// Tanzil Uthmani 1.1 numbers Al-Fatiha with the basmala as ayah 1 (Hafs /
/// Kufan count). For each ayah n the ring showing the Arabic-Indic digit for n
/// must sit right after the end of ayah n's text, on the same line (in RTL:
/// immediately to its left), and tapping that ring must select ayah n.
void main() {
  setUpAll(loadAppFonts);
  final surah = parseSurahAsset(
    File(BundledQuranTextRepository.assetPath(1)).readAsStringSync(),
  )!;

  test('source numbering: ayahs 1–7 in order, basmala counted as ayah 1', () {
    expect([for (final a in surah.ayahs) a.number], [1, 2, 3, 4, 5, 6, 7]);
    // Tanzil's own basmala line for Al-Fatiha is ayah 1 (Hafs / Kufan
    // count); the text itself is checked byte for byte in
    // al_fatiha_text_test.dart.
    expect(surah.ayahs.first.text.split(' ').length, 4);
  });

  /// Character range of each ayah's own text in the laid-out paragraph.
  Map<int, TextRange> ayahRanges(RenderParagraph p) {
    final out = <int, TextRange>{};
    var offset = 0;
    p.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        final i = surah.ayahs.indexWhere((a) => a.text == span.text);
        if (i >= 0) {
          out[i + 1] = TextRange(
            start: offset,
            end: offset + span.text!.length,
          );
        }
        offset += span.text!.length;
      } else if (span is PlaceholderSpan) {
        offset += 1;
      }
      return true;
    });
    return out;
  }

  /// The global rect where the number [n] is drawn, whichever way markers are
  /// implemented (a widget, or digits inside the paragraph).
  Rect markerRect(WidgetTester tester, int n) {
    final digits = localizeDigits('$n', const Locale('ar'));
    final asWidget = find.descendant(
      of: find.byKey(const ValueKey('quran-text')),
      matching: find.text(digits),
    );
    if (asWidget.evaluate().isNotEmpty) return tester.getRect(asWidget.first);
    final p = quranParagraph(tester);
    var offset = 0;
    Rect? found;
    p.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        final t = span.text!;
        if (found == null && t.trim() == digits) {
          final start = offset + t.indexOf(digits);
          final boxes = p.getBoxesForSelection(
            TextSelection(
              baseOffset: start,
              extentOffset: start + digits.length,
            ),
          );
          var r = boxes.first.toRect();
          for (final b in boxes.skip(1)) {
            r = r.expandToInclude(b.toRect());
          }
          found = Rect.fromPoints(
            p.localToGlobal(r.topLeft),
            p.localToGlobal(r.bottomRight),
          );
        }
        offset += t.length;
      } else if (span is PlaceholderSpan) {
        offset += 1;
      }
      return true;
    });
    if (found == null) throw StateError('no marker for $n');
    return found!;
  }

  /// Global rect of the last glyph run of ayah [n] (its end, in RTL the
  /// left-most box on its last line).
  Rect ayahEnd(WidgetTester tester, int n) {
    final p = quranParagraph(tester);
    final range = ayahRanges(p)[n]!;
    final boxes = p
        .getBoxesForSelection(
          TextSelection(baseOffset: range.start, extentOffset: range.end),
        )
        .map((b) => b.toRect())
        .toList();
    final lastTop = boxes.map((b) => b.top).reduce((a, b) => a > b ? a : b);
    final last = boxes
        .where((b) => (b.top - lastTop).abs() < 1)
        .reduce((a, b) => a.left < b.left ? a : b);
    return Rect.fromPoints(
      p.localToGlobal(last.topLeft),
      p.localToGlobal(last.bottomRight),
    );
  }

  for (final (locale, width) in [
    ('en', 384.0),
    ('ar', 384.0),
    ('en', 320.0),
    ('en', 600.0),
  ]) {
    testWidgets('each number n is drawn right after ayah n ($locale, '
        '${width.toInt()} dp)', (tester) async {
      await pumpApp(
        tester,
        locale: locale,
        location: AppRoutes.quran,
        physicalSize: Size(width * referenceDpr, 1600 * referenceDpr),
      );
      for (var n = 1; n <= 7; n++) {
        final end = ayahEnd(tester, n);
        final marker = markerRect(tester, n);
        // Same line: the marker's centre lies within the ayah end's line box.
        expect(
          marker.center.dy,
          inInclusiveRange(end.top, end.bottom),
          reason: 'number $n must be on the line where ayah $n ends',
        );
        // Immediately after the end of the ayah (RTL: to its left), with
        // nothing but a space in between.
        expect(
          marker.right,
          lessThanOrEqualTo(end.left + 1),
          reason: 'number $n must come after (left of) the end of ayah $n',
        );
        expect(
          end.left - marker.right,
          lessThan(24),
          reason: 'number $n must directly follow ayah $n',
        );
      }
    });
  }

  testWidgets('tapping number n selects ayah n', (tester) async {
    await pumpApp(tester, location: AppRoutes.quran);
    for (var n = 1; n <= 7; n++) {
      await tester.tapAt(markerRect(tester, n).center);
      await tester.pumpAndSettle();
      final highlighted = [
        for (final (text, bg) in renderedAyahSpans(tester))
          if (bg != null) surah.ayahs.indexWhere((a) => a.text == text) + 1,
      ];
      expect(highlighted, [n], reason: 'tapped number $n');
    }
  });
}
