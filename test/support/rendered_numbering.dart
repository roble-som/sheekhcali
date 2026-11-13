import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/core/l10n/localized_digits.dart';
import 'package:sheekhcali/features/quran/domain/quran_text_availability.dart';

import 'synthetic_alignment.dart' show quranParagraph;

/// Character range of each ayah's displayed text in the laid-out paragraph,
/// found by walking the spans actually handed to the renderer.
Map<int, TextRange> renderedAyahRanges(RenderParagraph p, SurahText surah) {
  // Matched in reading order: some ayahs repeat an earlier ayah's exact text
  // (for example 2:141 and 2:134), so text alone can't identify them.
  final out = <int, TextRange>{};
  var next = 0;
  var offset = 0;
  p.text.visitChildren((span) {
    if (span is TextSpan && span.text != null) {
      if (next < surah.ayahs.length &&
          span.text == surah.ayahs[next].displayText) {
        out[surah.ayahs[next].number] = TextRange(
          start: offset,
          end: offset + span.text!.length,
        );
        next++;
      }
      offset += span.text!.length;
    } else if (span is PlaceholderSpan) {
      offset += 1;
    }
    return true;
  });
  return out;
}

/// Global rect of each drawn number, keyed by the number it shows.
Map<int, Rect> renderedMarkerRects(RenderParagraph p) {
  final out = <int, Rect>{};
  var offset = 0;
  p.text.visitChildren((span) {
    if (span is TextSpan && span.text != null) {
      final t = span.text!;
      final digits = t.trim();
      if (digits.isNotEmpty && RegExp(r'^[٠-٩]+$').hasMatch(digits)) {
        final n = int.parse(
          String.fromCharCodes(digits.runes.map((r) => r - 0x0660 + 0x30)),
        );
        final start = offset + t.indexOf(digits);
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + digits.length),
        );
        var r = boxes.first.toRect();
        for (final b in boxes.skip(1)) {
          r = r.expandToInclude(b.toRect());
        }
        out[n] = Rect.fromPoints(
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
  return out;
}

/// Global rect of the end of ayah [range] (RTL: left-most box on its last
/// line).
Rect renderedAyahEnd(RenderParagraph p, TextRange range) {
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

/// Checks every ayah of [surah] as rendered: exactly one number per ayah,
/// equal to the ayah's ID, drawn right after the ayah's end on the same line.
/// Returns a list of problems (empty when all is well).
List<String> checkRenderedNumbering(WidgetTester tester, SurahText surah) {
  final p = quranParagraph(tester);
  final ranges = renderedAyahRanges(p, surah);
  final markers = renderedMarkerRects(p);
  final problems = <String>[];
  if (markers.length != surah.ayahs.length) {
    problems.add(
      '${surah.number}: ${markers.length} numbers drawn for '
      '${surah.ayahs.length} ayahs',
    );
  }
  for (final a in surah.ayahs) {
    final range = ranges[a.number];
    final marker = markers[a.number];
    if (range == null || marker == null) {
      problems.add('${surah.number}:${a.number} missing text or number');
      continue;
    }
    final end = renderedAyahEnd(p, range);
    final sameLine =
        marker.center.dy >= end.top && marker.center.dy <= end.bottom;
    final after = marker.right <= end.left + 1;
    final adjacent = end.left - marker.right < 24;
    if (!sameLine || !after || !adjacent) {
      problems.add(
        '${surah.number}:${a.number} number '
        '${localizeDigits('${a.number}', const Locale('ar'))} misplaced '
        '(same line $sameLine, after $after, adjacent $adjacent)',
      );
    }
  }
  return problems;
}
