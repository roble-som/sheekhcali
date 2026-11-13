import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/l10n/localized_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tafsir_audio/domain/alignment.dart';
import '../../domain/quran_text_availability.dart';

/// How an ayah is currently marked.
enum AyahMark { none, selected, reading, explaining }

/// Al-Fatiha (and later any surah) as continuous Quran text: a surah header,
/// the ayahs flowing right to left with ayah-end markers, and the source
/// attribution required by the Tanzil terms.
///
/// The text of each ayah is passed to the renderer **exactly as stored**: no
/// trimming, joining or normalisation (QURAN_AND_AUDIO_ACCURACY §3.1, display
/// path test in test/quran/).
class SurahTextView extends StatefulWidget {
  const SurahTextView({
    super.key,
    required this.surah,
    required this.dark,
    required this.marks,
    required this.onAyahTap,
    required this.onAyahLongPress,
    required this.onSourceTap,
    this.fontSize = 28,
  });

  final SurahText surah;
  final bool dark;

  /// ayah number → mark. Missing means [AyahMark.none].
  final Map<int, AyahMark> marks;
  final ValueChanged<int> onAyahTap;
  final ValueChanged<int> onAyahLongPress;
  final VoidCallback onSourceTap;
  final double fontSize;

  @override
  State<SurahTextView> createState() => _SurahTextViewState();
}

class _SurahTextViewState extends State<SurahTextView> {
  final _taps = <int, TapGestureRecognizer>{};
  final _paragraphKey = GlobalKey();

  @override
  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    super.dispose();
  }

  /// One recogniser per ayah, shared by its text and its number.
  TapGestureRecognizer _tap(int n) =>
      _taps.putIfAbsent(n, TapGestureRecognizer.new)
        ..onTap = () => widget.onAyahTap(n);

  Color? _background(AyahMark mark) {
    final dark = widget.dark;
    return switch (mark) {
      AyahMark.none => null,
      // Reference 04's selection colour.
      AyahMark.selected || AyahMark.reading =>
        dark ? ReaderColors.highlight : const Color(0xFFE3D3B4),
      // Lighter while the Sheikh explains (the side marker adds a non-colour cue).
      AyahMark.explaining =>
        dark ? const Color(0xFF4A4036) : const Color(0xFFF1E8D6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = widget.dark ? ReaderColors.inkDark : ReaderColors.inkLight;
    final surah = widget.surah;
    final locale = Localizations.localeOf(context);
    final revelation = surah.revelation == 'Meccan'
        ? l10n.revelationMakki
        : l10n.revelationMadani;

    final layout = AyahLayout(surah);
    final markerStyle = TextStyle(
      fontFamily: AppFonts.quran,
      fontSize: 15,
      height: 1,
      color: ink,
    );
    final spans = <InlineSpan>[];
    final rings = <_Ring>[];
    for (final slot in layout.slots) {
      final ayah = surah.ayahs[slot.index];
      final mark = widget.marks[ayah.number] ?? AyahMark.none;
      final bg = _background(mark);
      final semantics = l10n.quranAyahSemantics(
        localizeDigits('${ayah.number}', const Locale('ar')),
      );
      rings.add(
        _Ring(
          slot: slot,
          background: bg,
          explaining: mark == AyahMark.explaining,
        ),
      );
      spans
        ..add(
          TextSpan(
            text: ayah.text, // verbatim
            recognizer: _tap(ayah.number),
            semanticsLabel: '$semantics. ${ayah.text}',
            style: bg == null ? null : TextStyle(backgroundColor: bg),
          ),
        )
        ..add(const TextSpan(text: AyahLayout.beforeMarker))
        // The number is text in the same paragraph, so it is always laid out
        // right after its ayah. (Inline widgets are not: in right-to-left
        // lines Flutter positions them in left-to-right order, which showed
        // e.g. ③ after ayah 2 and ② after ayah 3.) The ring is painted
        // behind it by _AyahRingPainter.
        ..add(
          TextSpan(
            text: AyahLayout.markerText(ayah.number),
            recognizer: _tap(ayah.number),
            semanticsLabel: semantics,
            style: markerStyle,
          ),
        )
        ..add(const TextSpan(text: AyahLayout.afterMarker));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SurahHeader(name: surah.nameArabic, dark: widget.dark),
        const SizedBox(height: 6),
        Text(
          localizeDigits(
            l10n.surahMeta(revelation, l10n.ayahCount(surah.ayahs.length)),
            locale,
          ),
          textAlign: TextAlign.center,
          style: context.text.listSubtitle.copyWith(
            color: widget.dark
                ? const Color(0xB3FFFFFF)
                : ReaderColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        // Long press anywhere on an ayah's text selects it.
        _LongPressByAyah(
          layout: layout,
          paragraphKey: _paragraphKey,
          onLongPress: widget.onAyahLongPress,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomPaint(
              painter: _AyahRingPainter(
                paragraphKey: _paragraphKey,
                rings: rings,
                ring: widget.dark
                    ? ReaderColors.ayahMarker
                    : const Color(0xFF3E6A50),
              ),
              child: KeyedSubtree(
                key: const ValueKey('quran-text'),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.quran,
                      fontSize: widget.fontSize,
                      height: 2.15,
                      color: ink,
                    ),
                    children: spans,
                  ),
                  key: _paragraphKey,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  // The Quran text never shrinks below its reading size
                  // because of the system text scale
                  // (DESIGN_SYSTEM_SPECIFICATION §3.3).
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(minScaleFactor: 1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _SourceLine(surah: surah, dark: widget.dark, onTap: widget.onSourceTap),
      ],
    );
  }
}

/// Converts a long press on the text into the ayah under the finger, using the
/// laid-out text (TextSpan recognisers support only one gesture each).
class _LongPressByAyah extends StatelessWidget {
  const _LongPressByAyah({
    required this.layout,
    required this.paragraphKey,
    required this.onLongPress,
    required this.child,
  });

  final AyahLayout layout;
  final GlobalKey paragraphKey;
  final ValueChanged<int> onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (details) {
        final paragraph = paragraphKey.currentContext?.findRenderObject();
        if (paragraph is! RenderParagraph) return;
        final local = paragraph.globalToLocal(details.globalPosition);
        final offset = paragraph.getPositionForOffset(local).offset;
        final n = layout.ayahAt(offset);
        if (n != null) onLongPress(n);
      },
      child: child,
    );
  }
}

/// Where each ayah and its number sit in the reader's paragraph (character
/// offsets). The renderer, the long-press lookup and the tests all use this,
/// so they can never disagree.
///
/// Per ayah: its text (verbatim), a no-break space (so the number never
/// starts a line on its own), the number in Arabic-Indic digits padded with
/// figure spaces (room for the ring), then a normal space.
@immutable
class AyahLayout {
  AyahLayout(SurahText surah) : slots = _build(surah);

  static const beforeMarker = '\u00A0';
  static const afterMarker = ' ';
  static const _pad = '\u2007\u2007'; // figure spaces: no line break inside

  static String digits(int n) => localizeDigits('$n', const Locale('ar'));
  static String markerText(int n) => '$_pad${digits(n)}$_pad';

  final List<AyahSlot> slots;

  static List<AyahSlot> _build(SurahText surah) {
    final out = <AyahSlot>[];
    var cursor = 0;
    for (var i = 0; i < surah.ayahs.length; i++) {
      final a = surah.ayahs[i];
      final textStart = cursor;
      final textEnd = textStart + a.text.length;
      final markerStart = textEnd + beforeMarker.length;
      final marker = markerText(a.number);
      final digitsStart = markerStart + _pad.length;
      final markerEnd = markerStart + marker.length;
      out.add(
        AyahSlot(
          index: i,
          number: a.number,
          text: TextRange(start: textStart, end: textEnd),
          marker: TextRange(start: markerStart, end: markerEnd),
          digits: TextRange(
            start: digitsStart,
            end: digitsStart + digits(a.number).length,
          ),
        ),
      );
      cursor = markerEnd + afterMarker.length;
    }
    return out;
  }

  /// The ayah owning the character at [offset] (its text, its number, or the
  /// spaces around them).
  int? ayahAt(int offset) {
    for (final s in slots) {
      if (offset < s.marker.end + afterMarker.length) return s.number;
    }
    return slots.isEmpty ? null : slots.last.number;
  }
}

/// One ayah's place in the paragraph.
@immutable
class AyahSlot {
  const AyahSlot({
    required this.index,
    required this.number,
    required this.text,
    required this.marker,
    required this.digits,
  });

  final int index;
  final int number;
  final TextRange text;

  /// The padded number (the ring's area).
  final TextRange marker;

  /// Just the digits.
  final TextRange digits;
}

@immutable
class _Ring {
  const _Ring({
    required this.slot,
    required this.background,
    required this.explaining,
  });

  final AyahSlot slot;
  final Color? background;
  final bool explaining;

  @override
  bool operator ==(Object other) =>
      other is _Ring &&
      other.slot.number == slot.number &&
      other.slot.marker == slot.marker &&
      other.background == background &&
      other.explaining == explaining;

  @override
  int get hashCode =>
      Object.hash(slot.number, slot.marker, background, explaining);
}

/// The traditional ayah-end ornament, painted behind each number where the
/// paragraph actually laid it out: a ring, plus the ayah's highlight and, while
/// the Sheikh explains it, a gold bar on the reading-start side.
class _AyahRingPainter extends CustomPainter {
  _AyahRingPainter({
    required this.paragraphKey,
    required this.rings,
    required this.ring,
  });

  final GlobalKey paragraphKey;
  final List<_Ring> rings;
  final Color ring;

  static Rect? _union(RenderParagraph p, TextRange r) {
    final boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: r.start, extentOffset: r.end),
    );
    if (boxes.isEmpty) return null;
    var out = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      out = out.expandToInclude(b.toRect());
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = paragraphKey.currentContext?.findRenderObject();
    if (p is! RenderParagraph || !p.hasSize) return;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = ring;
    for (final r in rings) {
      final area = _union(p, r.slot.marker);
      final digits = _union(p, r.slot.digits);
      if (area == null || digits == null) continue;
      final centre = Offset(area.center.dx, digits.center.dy);
      final radius = (digits.width / 2 + 7).clamp(15.0, area.width / 2);
      final block = Rect.fromCenter(
        center: centre,
        width: area.width,
        height: radius * 2 + 8,
      );
      if (r.background != null) {
        canvas.drawRect(block, Paint()..color = r.background!);
      }
      if (r.explaining) {
        // RTL: the reading-start side is the right.
        canvas.drawRect(
          Rect.fromLTRB(block.right - 3, block.top, block.right, block.bottom),
          Paint()..color = HomeColors.gold,
        );
      }
      canvas.drawCircle(centre, radius - 0.8, stroke);
    }
  }

  @override
  bool shouldRepaint(_AyahRingPainter old) =>
      old.ring != ring || !listEquals(old.rings, rings);
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name, required this.dark});

  final String name;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final line = dark ? const Color(0xFF6E8F7A) : const Color(0xFF7E9C88);
    final gold = HomeColors.goldRule;
    return Semantics(
      header: true,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(color: gold.withValues(alpha: 0.85), width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: line.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(4),
            color: dark ? const Color(0xFF0E1A16) : const Color(0xFFF4F1E8),
          ),
          alignment: Alignment.center,
          child: Text(
            // "Surah" + the name from the source metadata. Always Arabic: it is
            // part of the Quran page, not interface copy.
            'سورة $name',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppFonts.quran,
              fontSize: 22,
              height: 1.3,
              color: dark ? ReaderColors.inkDark : ReaderColors.inkLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({
    required this.surah,
    required this.dark,
    required this.onTap,
  });

  final SurahText surah;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final muted = dark ? const Color(0xB3FFFFFF) : ReaderColors.textSecondary;
    final signed = surah.reviewerSignedOff;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.quranSourceLine(surah.source.version),
                      textAlign: TextAlign.center,
                      style: styles.listSubtitle.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color:
                  (signed ? SemanticColors.verified : const Color(0xFFB99645))
                      .withValues(alpha: 0.8),
            ),
          ),
          child: Text(
            signed
                ? l10n.reviewDone(surah.reviewer!, surah.reviewedAt!)
                : l10n.reviewPending,
            style: styles.placeholderLabel.copyWith(
              color: signed
                  ? (dark ? const Color(0xFF9FD1B0) : SemanticColors.verified)
                  : (dark ? const Color(0xFFE2C77F) : SemanticColors.draft),
            ),
          ),
        ),
      ],
    );
  }
}

/// Maps a verified span kind to the ayah mark used while it plays.
AyahMark markForKind(SpanKind kind) =>
    kind == SpanKind.reading ? AyahMark.reading : AyahMark.explaining;
