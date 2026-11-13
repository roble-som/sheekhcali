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

  @override
  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    super.dispose();
  }

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

    final spans = <InlineSpan>[];
    for (final ayah in surah.ayahs) {
      final mark = widget.marks[ayah.number] ?? AyahMark.none;
      final bg = _background(mark);
      spans
        ..add(
          TextSpan(
            text: ayah.text, // verbatim
            recognizer: (_tap(ayah.number)
              ..onTap = () => widget.onAyahTap(ayah.number)),
            semanticsLabel:
                '${l10n.quranAyahSemantics(localizeDigits('${ayah.number}', const Locale('ar')))}. ${ayah.text}',
            style: bg == null ? null : TextStyle(backgroundColor: bg),
          ),
        )
        ..add(const TextSpan(text: ' '))
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onLongPress: () => widget.onAyahLongPress(ayah.number),
              onTap: () => widget.onAyahTap(ayah.number),
              child: _AyahMarker(
                number: ayah.number,
                dark: widget.dark,
                background: bg,
                explaining: mark == AyahMark.explaining,
              ),
            ),
          ),
        )
        ..add(const TextSpan(text: ' '));
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
          surah: surah,
          onLongPress: widget.onAyahLongPress,
          child: Directionality(
            textDirection: TextDirection.rtl,
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
              key: const ValueKey('quran-text'),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              // The Quran text never shrinks below its reading size because of
              // the system text scale (DESIGN_SYSTEM_SPECIFICATION §3.3).
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(minScaleFactor: 1),
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
    required this.surah,
    required this.onLongPress,
    required this.child,
  });

  final SurahText surah;
  final ValueChanged<int> onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final paragraph = _findParagraph(context);
        if (paragraph == null) return;
        final local = paragraph.globalToLocal(details.globalPosition);
        final offset = paragraph.getPositionForOffset(local).offset;
        final n = _ayahAtOffset(offset);
        if (n != null) onLongPress(n);
      },
      child: child,
    );
  }

  RenderParagraph? _findParagraph(BuildContext context) {
    RenderParagraph? found;
    void visit(Element e) {
      if (found != null) return;
      final ro = e.renderObject;
      if (ro is RenderParagraph &&
          e.widget.key == const ValueKey('quran-text')) {
        found = ro;
        return;
      }
      e.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return found;
  }

  /// Maps a character offset in the laid-out text back to an ayah. Each ayah
  /// contributes its text, a space, one placeholder (marker) and a space.
  int? _ayahAtOffset(int offset) {
    var cursor = 0;
    for (final a in surah.ayahs) {
      final end = cursor + a.text.length + 3;
      if (offset < end) return a.number;
      cursor = end;
    }
    return surah.ayahs.isEmpty ? null : surah.ayahs.last.number;
  }
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

/// The traditional ayah-end ornament: a ring with the ayah number in
/// Arabic-Indic digits (always, as on a mushaf page).
class _AyahMarker extends StatelessWidget {
  const _AyahMarker({
    required this.number,
    required this.dark,
    required this.background,
    required this.explaining,
  });

  final int number;
  final bool dark;
  final Color? background;
  final bool explaining;

  @override
  Widget build(BuildContext context) {
    final ring = dark ? ReaderColors.ayahMarker : const Color(0xFF3E6A50);
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: explaining
              ? const BorderDirectional(
                  start: BorderSide(color: HomeColors.gold, width: 3),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 1.6),
          ),
          child: Text(
            localizeDigits('$number', const Locale('ar')),
            style: TextStyle(
              fontFamily: AppFonts.quran,
              fontSize: 15,
              height: 1,
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
