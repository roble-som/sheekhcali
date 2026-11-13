import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/core/theme/app_colors.dart';

/// WCAG 2.1 contrast ratio. [fg] may be translucent; it is composited over [bg].
double contrast(Color fg, Color bg) {
  final a = fg.a;
  final mixed = Color.from(
    alpha: 1,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(mixed);
  final l2 = lum(bg);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Every text/background pair used in Phase 1 must pass WCAG AA for normal
  // text (4.5:1). DESIGN_SYSTEM_SPECIFICATION §10; DV-01 and DV-02 fix the two
  // reference pairs that failed.
  final textPairs = <String, (Color, Color)>{
    'weekday on page': (HomeColors.green800, HomeColors.bg),
    'hijri date on page': (HomeColors.green900, HomeColors.bg),
    'gregorian date on page': (HomeColors.textDate, HomeColors.bg),
    'section label on page': (HomeColors.textMuted, HomeColors.bg),
    'tile title on cool tile': (HomeColors.text, HomeColors.tileCoolBottom),
    'tile subtitle on cool tile': (
      HomeColors.textMuted,
      HomeColors.tileCoolBottom,
    ),
    'tile subtitle on warm tile': (
      HomeColors.textMuted,
      HomeColors.tileWarmBottom,
    ),
    'dhikr label on card': (HomeColors.goldLabel, HomeColors.dhikrTop),
    'dhikr text on card': (HomeColors.onDark, HomeColors.dhikrTop),
    'Quran title on card (light end)': (
      HomeColors.onDark,
      HomeColors.cardGradStart,
    ),
    'Quran subtitle on card (DV-02)': (
      HomeColors.onCardMuted,
      HomeColors.cardGradStart,
    ),
    'app bar text on teal': (ReaderColors.onBar, ReaderColors.bar),
    'drawer item on white': (ReaderColors.text, ReaderColors.surface),
    'sheet secondary on white (DV-01)': (
      ReaderColors.textSecondary,
      ReaderColors.surface,
    ),
    'ink on dark page': (ReaderColors.inkDark, ReaderColors.pageDark),
    'ink on light page': (ReaderColors.inkLight, ReaderColors.pageLight),
    'white on ayah highlight': (ReaderColors.inkDark, ReaderColors.highlight),
  };

  for (final entry in textPairs.entries) {
    test('text contrast ≥ 4.5:1: ${entry.key}', () {
      final (fg, bg) = entry.value;
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });
  }

  test('drawer icons ≥ 3:1 (non-text)', () {
    expect(
      contrast(ReaderColors.icon, ReaderColors.surface),
      greaterThanOrEqualTo(3),
    );
  });

  test('the measured reference value really fails, documenting DV-01', () {
    expect(
      contrast(const Color(0xFF828284), ReaderColors.surface),
      lessThan(4.5),
    );
  });
}
