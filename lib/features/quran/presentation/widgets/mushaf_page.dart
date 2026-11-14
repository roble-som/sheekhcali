import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/localized_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/reading_state.dart';
import '../../data/quran_text_repository.dart';
import '../../domain/quran_metadata.dart';
import '../../domain/quran_text_availability.dart';
import 'surah_text_view.dart';

/// One Madinah Mushaf page: exactly the ayahs the verified page data puts on
/// [page] (QuranMetadata.pageSegments), each surah's part shown by
/// [SurahTextView] with its header and basmala where the surah starts.
///
/// The page *boundaries* are the Mushaf's; the line layout is the app's own
/// text flow (the printed layout needs the KFGQPC fonts, P-24), and the
/// source dialog says so.
class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({
    super.key,
    required this.page,
    required this.metadata,
    required this.dark,
    required this.marks,
    required this.fontSize,
    required this.onAyahTap,
    required this.onAyahLongPress,
    required this.onSourceTap,
    required this.onPlaceSettled,
    this.initialAyah,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final QuranMetadata metadata;
  final bool dark;
  final Map<AyahRef, AyahMark> marks;
  final double fontSize;
  final ValueChanged<AyahRef> onAyahTap;
  final void Function(SurahText surah, int ayah) onAyahLongPress;
  final ValueChanged<SurahText> onSourceTap;

  /// The ayah at the top of the page after the user scrolled within it.
  final ValueChanged<AyahRef> onPlaceSettled;

  /// Scrolled into view once, when the page first shows its text.
  final AyahRef? initialAyah;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  ConsumerState<MushafPage> createState() => MushafPageState();
}

/// Public so the reader can auto-scroll the page and tests can find ayahs.
class MushafPageState extends ConsumerState<MushafPage> {
  final scroll = ScrollController();
  final _texts = <int, GlobalKey<SurahTextViewState>>{};
  bool _didInitialScroll = false;

  GlobalKey<SurahTextViewState> _keyFor(int surah) =>
      _texts.putIfAbsent(surah, GlobalKey<SurahTextViewState>.new);

  /// The text view showing [surah] on this page (null if not shown).
  SurahTextViewState? textOf(int surah) => _texts[surah]?.currentState;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  RenderBox? get _viewport {
    if (!scroll.hasClients) return null;
    final ro = scroll.position.context.storageContext.findRenderObject();
    return ro is RenderBox ? ro : null;
  }

  /// Scrolls so that [place] starts near the top of the page.
  void scrollToAyah(AyahRef place) {
    final viewport = _viewport;
    final top = textOf(place.surah)?.ayahGlobalTop(place.ayah);
    if (viewport == null || top == null) return;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    scroll.jumpTo(
      (scroll.offset + top.dy - viewportTop - 16).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      ),
    );
  }

  /// The ayah near the top of the visible part of the page.
  AyahRef? placeAtTop() {
    final viewport = _viewport;
    if (viewport == null) return null;
    final at =
        viewport.localToGlobal(Offset.zero) +
        Offset(viewport.size.width / 2, 40);
    AyahRef? out;
    for (final seg in widget.metadata.pageSegments(widget.page)) {
      final view = textOf(seg.surah);
      final top = view?.paragraphGlobalTop();
      if (view == null || top == null) continue;
      if (out != null && top > at.dy) break;
      final ayah = view.ayahAtGlobal(at);
      if (ayah != null) out = AyahRef(seg.surah, ayah);
    }
    return out;
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final place = placeAtTop();
    if (place != null) widget.onPlaceSettled(place);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = widget.metadata;
    final segments = meta.pageSegments(widget.page);
    final texts = [
      for (final seg in segments) ref.watch(surahTextProvider(seg.surah)),
    ];
    final ink = widget.dark ? HomeColors.goldLabel : ReaderColors.icon;
    if (texts.any((t) => t.isLoading)) {
      return Center(child: CircularProgressIndicator(color: ink));
    }
    final verified = [
      for (final t in texts)
        if (t.value case QuranTextVerified(:final surah)) surah,
    ];
    if (verified.length != segments.length) {
      // Never show text that failed verification, not even part of a page.
      return _PageNotice(dark: widget.dark, text: l10n.pageTextUnverified);
    }

    final initial = widget.initialAyah;
    if (!_didInitialScroll) {
      _didInitialScroll = true;
      if (initial != null &&
          meta.pageOf(initial.surah, initial.ayah) == widget.page &&
          !(initial.ayah == segments.first.firstAyah &&
              initial.surah == segments.first.surah)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) scrollToAyah(initial);
        });
      }
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: SingleChildScrollView(
        key: ValueKey('page-scroll-${widget.page}'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(
                  page: widget.page,
                  surahs: verified,
                  juz: meta.juzOf(
                    segments.first.surah,
                    segments.first.firstAyah,
                  ),
                  dark: widget.dark,
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < segments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 22),
                  SurahTextView(
                    key: _keyFor(segments[i].surah),
                    surah: verified[i],
                    firstAyah: segments[i].firstAyah,
                    lastAyah: segments[i].lastAyah,
                    showSource: false,
                    dark: widget.dark,
                    fontSize: widget.fontSize,
                    marks: {
                      for (final e in widget.marks.entries)
                        if (e.key.surah == segments[i].surah)
                          e.key.ayah: e.value,
                    },
                    onAyahTap: (n) =>
                        widget.onAyahTap(AyahRef(segments[i].surah, n)),
                    onAyahLongPress: (n) =>
                        widget.onAyahLongPress(verified[i], n),
                    onSourceTap: () => widget.onSourceTap(verified[i]),
                  ),
                ],
                const SizedBox(height: 22),
                _PageFooter(
                  page: widget.page,
                  dark: widget.dark,
                  onPrevious: widget.onPrevious,
                  onNext: widget.onNext,
                ),
                const SizedBox(height: 8),
                QuranSourceLine(
                  surah: verified.first,
                  dark: widget.dark,
                  onTap: () => widget.onSourceTap(verified.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's running head, as in a printed Mushaf: the surah(s) on the page
/// at the start, the juz at the end.
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.page,
    required this.surahs,
    required this.juz,
    required this.dark,
  });

  final int page;
  final List<SurahText> surahs;
  final int? juz;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final arabic = locale.languageCode == 'ar';
    final muted = dark ? const Color(0xB3FFFFFF) : ReaderColors.textSecondary;
    final style = context.text.listSubtitle.copyWith(
      color: muted,
      fontSize: 13,
    );
    final names = surahs
        .map((s) => arabic ? s.nameArabic : s.nameTransliterated)
        .join(' · ');
    return Container(
      key: const ValueKey('page-header'),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HomeColors.goldRule.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              names,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (juz != null)
            Text(localizeDigits(l10n.juzTitle('$juz'), locale), style: style),
        ],
      ),
    );
  }
}

/// Page number between previous and next page buttons. Laid out right to
/// left like the Mushaf: the previous page is on the right, the next on the
/// left, matching the swipe direction.
class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.page,
    required this.dark,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool dark;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final ink = dark ? ReaderColors.inkDark : ReaderColors.inkLight;
    final icon = dark ? HomeColors.goldLabel : ReaderColors.icon;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey('previous-page'),
            tooltip: l10n.previousPage,
            onPressed: onPrevious,
            color: icon,
            // Chevrons mirror in right-to-left layout: this one is drawn
            // pointing right, out towards the previous page.
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 12),
          Container(
            key: const ValueKey('page-number'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: HomeColors.goldRule.withValues(alpha: 0.8),
              ),
            ),
            child: Semantics(
              label: l10n.pageLabel(localizeDigits('$page', locale)),
              excludeSemantics: true,
              child: Text(
                // The Mushaf's own page number, in Arabic-Indic digits as
                // printed; never an ayah number.
                AyahLayout.digits(page),
                style: TextStyle(
                  fontFamily: AppFonts.quran,
                  fontSize: 16,
                  height: 1.4,
                  color: ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            key: const ValueKey('next-page'),
            tooltip: l10n.nextPage,
            onPressed: onNext,
            color: icon,
            // Drawn pointing left, towards the next page (see above).
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PageNotice extends StatelessWidget {
  const _PageNotice({required this.dark, required this.text});

  final bool dark;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.listSubtitle.copyWith(
          color: dark ? const Color(0xB3FFFFFF) : ReaderColors.textSecondary,
        ),
      ),
    ),
  );
}
