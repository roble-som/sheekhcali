import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/calendar/date_labels.dart';
import '../../../core/l10n/localized_digits.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/presentation/app_drawer.dart';
import '../../navigation/presentation/drawer_back_scope.dart';
import '../../settings/application/preferences_controllers.dart';
import '../../tafsir_audio/application/fatiha_sync.dart';
import '../../tafsir_audio/application/tafsir_player.dart';
import '../../tafsir_audio/data/recording_repository.dart';
import '../../tafsir_audio/domain/candidates.dart';
import '../../tafsir_audio/domain/recording.dart';
import '../../tafsir_audio/domain/span_index.dart';
import '../../tafsir_audio/presentation/tafsir_player_bar.dart';
import '../application/reading_state.dart';
import '../data/quran_text_repository.dart';
import '../domain/quran_text_availability.dart';
import 'widgets/ayah_action_sheet.dart';
import 'widgets/mushaf_layout_preview.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_overflow_menu.dart';
import 'widgets/reading_controls.dart';
import 'widgets/surah_navigation.dart';
import 'widgets/surah_text_view.dart';

/// Quran reader (references 03–06, DESIGN_SYSTEM_SPECIFICATION §8.4 and §8.12).
///
/// Shows Al-Fatiha from the approved, verified source (Tanzil Uthmani 1.1,
/// C-25) in continuous reading layout (mushaf page layout is blocked on P-24),
/// with the Sheikh's Tafsir player and verified ayah highlighting. If the text
/// fails verification, it falls back to the labelled layout preview and never
/// shows unverified text.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({super.key, this.surah = 1, this.initialAyah});

  final int surah;

  /// Scroll to this ayah when the text first appears (index, juz, bookmark,
  /// search result or "continue reading").
  final int? initialAyah;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _moreKey = GlobalKey();
  int? _selectedAyah;
  bool _chromeVisible = true;
  final _scroll = ScrollController();
  final _textKey = GlobalKey<SurahTextViewState>();
  bool _didInitialScroll = false;
  Timer? _autoScroll;

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  bool get _isFatiha => widget.surah == 1;

  void _rememberPlace(int ayah) =>
      ref.read(lastReadProvider.notifier).set(AyahRef(widget.surah, ayah));

  /// Scrolls so that ayah [ayah] starts near the top of the reading area.
  void _scrollToAyah(int ayah) {
    if (!_scroll.hasClients) return;
    final top = _textKey.currentState?.ayahGlobalTop(ayah);
    final viewport = _scroll.position.context.storageContext.findRenderObject();
    if (top == null || viewport is! RenderBox) return;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final target = (_scroll.offset + top.dy - viewportTop - 16).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  /// Records the ayah at the top of the reading area after a scroll.
  bool _onScrollEnd(ScrollEndNotification n) {
    final viewport = _scroll.position.context.storageContext.findRenderObject();
    if (viewport is RenderBox) {
      final at =
          viewport.localToGlobal(const Offset(0, 0)) +
          Offset(viewport.size.width / 2, 40);
      final ayah = _textKey.currentState?.ayahAtGlobal(at);
      if (ayah != null) _rememberPlace(ayah);
    }
    return false;
  }

  /// Slow, steady scrolling for reading; any tap or the toolbar stops it.
  void _toggleAutoScroll() {
    if (_autoScroll != null) {
      _stopAutoScroll();
      return;
    }
    if (!_scroll.hasClients) return;
    showUnavailable(context, _l10n.autoScrollOn);
    _autoScroll = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scroll.hasClients) return;
      final next = _scroll.offset + 1.2;
      if (next >= _scroll.position.maxScrollExtent) {
        _stopAutoScroll();
        return;
      }
      _scroll.jumpTo(next);
    });
    setState(() {});
  }

  void _stopAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
    if (mounted) setState(() {});
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  SpanIndex? get _index => ref.read(fatihaSpanIndexProvider).value;

  /// The ayah the user last asked to hear explained.
  int? _tappedAyah;

  /// The segment playing because of that tap (reviewed, or an unreviewed
  /// candidate in review mode). Null once the user seeks elsewhere.
  AyahSegment? _segment;

  /// Plays the Sheikh's **explanation** of [ayah] from the start of its
  /// segment, switching segments if something is already playing, and stops at
  /// the segment's end.
  ///
  /// A reviewed span always wins. Without one, debug/testing builds play the
  /// AI-assisted candidate, labelled "unreviewed" in the player. With neither,
  /// nothing plays and the reader says so; never unrelated audio, never the
  /// opening recitation.
  Future<bool> _playExplanationFor(int ayah) async {
    setState(() => _tappedAyah = ayah);
    final recording = ref.read(fatihaRecordingProvider).value;
    if (recording is! RecordingReady) {
      showUnavailable(
        context,
        recording is RecordingPlatformUnsupported
            ? _l10n.recordingPhoneOnly
            : _l10n.unavailableRecording,
      );
      return false;
    }
    final reviewed = _index?.explanationForAyah(ayah);
    final candidates = await ref.read(fatihaCandidatesProvider.future);
    if (!mounted) return false;
    final candidate = reviewed == null
        ? candidates?.explanationForAyah(ayah)
        : null;
    final segment = reviewed != null
        ? AyahSegment.reviewed(ayah, reviewed)
        : candidate != null
        ? AyahSegment.candidate(ayah, candidate)
        : null;
    setState(() => _segment = segment);
    if (segment == null) {
      showUnavailable(
        context,
        _l10n.noReviewedExplanation(
          localizeDigits('$ayah', Localizations.localeOf(context)),
        ),
      );
      return false;
    }
    final player = ref.read(tafsirPlayerProvider);
    if (player.current.phase == TafsirPhase.idle ||
        player.current.phase == TafsirPhase.error) {
      await player.load(
        path: recording.path,
        title: _l10n.tafsirTitle,
        artist: _l10n.speakerName,
      );
      if (player.current.phase == TafsirPhase.error) return false;
    }
    await player.seek(Duration(milliseconds: segment.startMs));
    await player.play();
    return true;
  }

  /// Stops at the end of the tapped ayah's segment, so a tap plays that
  /// explanation and not the rest of the lesson.
  void _onPlayback(TafsirPlaybackState? previous, TafsirPlaybackState next) {
    final segment = _segment;
    if (segment == null || !next.isPlaying) return;
    if (segment.finished) {
      // Play pressed after the segment ended: carry on through the lesson.
      setState(() {
        _segment = null;
        _tappedAyah = null;
      });
      return;
    }
    final pos = next.position.inMilliseconds;
    if (pos >= segment.endMs && pos < segment.endMs + 5000) {
      ref.read(tafsirPlayerProvider).pause();
      setState(() => _segment = segment.asFinished());
    }
  }

  /// The user moved the playhead (slider or skip). Outside the tapped ayah's
  /// segment, the bar no longer plays "that ayah's explanation", so the
  /// highlight goes back to following reviewed spans only.
  void _onManualSeek(int targetMs) {
    final segment = _segment;
    if (segment != null &&
        targetMs >= segment.startMs &&
        targetMs < segment.endMs) {
      if (segment.finished) {
        setState(
          () => _segment = AyahSegment(
            ayah: segment.ayah,
            ayahs: segment.ayahs,
            startMs: segment.startMs,
            endMs: segment.endMs,
            reviewed: segment.reviewed,
            sourceId: segment.sourceId,
            confidence: segment.confidence,
          ),
        );
      }
      return;
    }
    if (_segment != null || _tappedAyah != null) {
      setState(() {
        _segment = null;
        _tappedAyah = null;
      });
    }
  }

  void _onAyahTap(int ayah) {
    _stopAutoScroll();
    _rememberPlace(ayah);
    if (_isFatiha) {
      _playExplanationFor(ayah);
      return;
    }
    // The Sheikh's Tafsir recording exists for Al-Fatiha only: select the
    // ayah and say so, never play another surah's audio.
    setState(() => _tappedAyah = _tappedAyah == ayah ? null : ayah);
    showUnavailable(context, _l10n.noTafsirForSurah);
  }

  Future<void> _onAyahLongPress(SurahText surah, int ayah) async {
    HapticFeedback.selectionClick();
    _stopAutoScroll();
    _rememberPlace(ayah);
    setState(() => _selectedAyah = ayah);
    final place = AyahRef(surah.number, ayah);
    final action = await showAyahActionSheet(
      context,
      bookmarked: ref.read(bookmarksProvider).contains(place),
    );
    if (!mounted) return;
    setState(() => _selectedAyah = null);
    if (action == null) return;
    final locale = Localizations.localeOf(context);
    switch (action) {
      case AyahAction.copy:
        final a = surah.ayah(ayah)!;
        final reference = _l10n.ayahReference(
          locale.languageCode == 'ar'
              ? surah.nameArabic
              : surah.nameTransliterated,
          localizeDigits('${surah.number}', locale),
          localizeDigits('$ayah', locale),
        );
        // The exact stored text, then its reference: never re-typed text.
        // The ayah as shown: exact stored text (without the basmala heading
        // the source prefixes to ayah 1 of most surahs), then its reference.
        await Clipboard.setData(
          ClipboardData(text: '${a.displayText}\n$reference'),
        );
        if (mounted) showUnavailable(context, _l10n.copiedAyah(reference));
      case AyahAction.playTafsir:
        if (_isFatiha) {
          await _playExplanationFor(ayah);
        } else {
          showUnavailable(context, _l10n.noTafsirForSurah);
        }
      case AyahAction.bookmark:
        final added = await ref.read(bookmarksProvider.notifier).toggle(place);
        if (mounted) {
          showUnavailable(
            context,
            added ? _l10n.bookmarkAdded : _l10n.bookmarkRemoved,
          );
        }
      case AyahAction.playToEnd:
      case AyahAction.playRecitationAndTafsir:
        showUnavailable(context, _l10n.unavailableRecitation);
      case AyahAction.tafsir:
        showUnavailable(context, _l10n.unavailableTafsirText);
      case AyahAction.addNote:
      case AyahAction.addItqan:
      case AyahAction.share:
        showUnavailable(context, _l10n.unavailableFeature);
    }
  }

  Future<void> _onMore() async {
    final dark = ref.read(readerDarkProvider);
    final action = await showReaderOverflowMenu(context, dark: dark);
    if (!mounted || action == null) return;
    switch (action) {
      case ReaderMenuAction.toggleTheme:
        await ref.read(readerDarkProvider.notifier).set(dark: !dark);
      case ReaderMenuAction.search:
        await context.push(AppRoutes.quranSearch);
      case ReaderMenuAction.controls:
        await showReadingControls(context);
      case ReaderMenuAction.goToPage:
        showUnavailable(context, _l10n.unavailableFeature);
    }
  }

  void _showPendingInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.quranTextPendingTitle),
        content: Text(_l10n.quranTextPendingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  void _showSource(SurahText surah) {
    showDialog<void>(
      context: context,
      builder: (context) => QuranSourceDialog(surah: surah),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(readerDarkProvider);
    final text = ref.watch(surahTextProvider(widget.surah));
    final index = ref.watch(fatihaSpanIndexProvider).value;
    final playback = ref.watch(tafsirPlaybackProvider).value;
    ref.listen(tafsirPlaybackProvider, (previous, next) {
      final value = next.value;
      if (value != null) _onPlayback(previous?.value, value);
    });
    final labels = DateLabels.build(
      now: ref.watch(clockProvider)(),
      locale: Localizations.localeOf(context),
      l10n: _l10n,
      converter: ref.watch(hijriConverterProvider),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final chromeDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    // Highlight: the user's selection wins; otherwise the verified span playing
    // now. Derived from the position alone, so seeking can't leave a stale mark.
    final marks = <int, AyahMark>{};
    if (_isFatiha && playback != null && playback.phase != TafsirPhase.idle) {
      final span = activeSpanAt(index, playback.position.inMilliseconds);
      if (span != null) {
        for (final n in span.ayahs) {
          marks[n] = markForKind(span.kind);
        }
      }
    }
    final tapped = _tappedAyah;
    if (tapped != null && marks.isEmpty) marks[tapped] = AyahMark.selected;
    if (_selectedAyah != null) marks[_selectedAyah!] = AyahMark.selected;

    final verified = text.value is QuranTextVerified
        ? (text.value! as QuranTextVerified).surah
        : null;
    final fontSize = ref.watch(quranFontSizeProvider);
    if (verified != null && !_didInitialScroll) {
      _didInitialScroll = true;
      final target = widget.initialAyah;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (target != null && target > 1) {
          _scrollToAyah(target);
        }
        _rememberPlace(target ?? 1);
      });
    }

    return Theme(
      data: AppTheme.reader(Theme.of(context), dark: dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: ReaderColors.bar,
        ),
        child: DrawerBackScope(
          scaffoldKey: _scaffoldKey,
          builder: (context, onDrawerChanged) => Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: onDrawerChanged,
            drawerScrimColor: kReaderScrim,
            drawer: const AppDrawer(),
            body: Column(
              children: [
                AnimatedSize(
                  duration: chromeDuration,
                  child: _chromeVisible
                      ? ReaderAppBar(
                          title: labels.hijriPadded ?? labels.gregorian,
                          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                          onBookmark: () => context.push(
                            AppRoutes.quranIndexTab('bookmarks'),
                          ),
                          onTranslation: () => showUnavailable(
                            context,
                            _l10n.unavailableTranslation,
                          ),
                          onIndex: () => context.push(AppRoutes.quranIndex),
                          onAutoScroll: _toggleAutoScroll,
                          autoScrolling: _autoScroll != null,
                          moreButtonKey: _moreKey,
                          onMore: _onMore,
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: MediaQuery.paddingOf(context).top,
                          child: const ColoredBox(color: ReaderColors.bar),
                        ),
                ),
                Expanded(
                  child: text.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: dark ? HomeColors.goldLabel : ReaderColors.icon,
                      ),
                    ),
                    error: (e, s) => _Preview(
                      dark: dark,
                      selected: _selectedAyah,
                      onInfo: _showPendingInfo,
                      onToggleChrome: () =>
                          setState(() => _chromeVisible = !_chromeVisible),
                      onLongPress: (n) {},
                    ),
                    data: (availability) => switch (availability) {
                      QuranTextVerified(:final surah) => GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          _stopAutoScroll();
                          setState(() => _chromeVisible = !_chromeVisible);
                        },
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: _onScrollEnd,
                          child: Center(
                            child: SingleChildScrollView(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                28,
                                20,
                                32,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 560,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SurahTextView(
                                      key: _textKey,
                                      surah: surah,
                                      dark: dark,
                                      marks: marks,
                                      fontSize: fontSize,
                                      onAyahTap: _onAyahTap,
                                      onAyahLongPress: (n) =>
                                          _onAyahLongPress(surah, n),
                                      onSourceTap: () => _showSource(surah),
                                    ),
                                    const SizedBox(height: 20),
                                    SurahNavigation(
                                      surah: surah.number,
                                      dark: dark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      QuranTextUnavailable() => _Preview(
                        dark: dark,
                        selected: _selectedAyah,
                        onInfo: _showPendingInfo,
                        onToggleChrome: () =>
                            setState(() => _chromeVisible = !_chromeVisible),
                        onLongPress: (n) async {
                          setState(() => _selectedAyah = n);
                          await showAyahActionSheet(context);
                          if (!mounted) return;
                          setState(() => _selectedAyah = null);
                          showUnavailable(
                            this.context,
                            _l10n.unavailableQuranText,
                          );
                        },
                      ),
                    },
                  ),
                ),
                if (verified != null && verified.number == 1)
                  TafsirPlayerBar(
                    index: index,
                    selectedAyah: _tappedAyah,
                    segment: _segment,
                    onManualSeek: _onManualSeek,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The labelled layout preview, used only when no verified text is available.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.dark,
    required this.selected,
    required this.onInfo,
    required this.onToggleChrome,
    required this.onLongPress,
  });

  final bool dark;
  final int? selected;
  final VoidCallback onInfo;
  final VoidCallback onToggleChrome;
  final ValueChanged<int> onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleChrome,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.246),
            child: MushafLayoutPreview(
              dark: dark,
              selectedAyah: selected,
              onAyahLongPress: onLongPress,
            ),
          ),
          PositionedDirectional(
            top: 12,
            start: 0,
            end: 0,
            child: Center(
              child: _PendingTextNotice(dark: dark, onInfo: onInfo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provenance and verification details for the Quran text on screen.
class QuranSourceDialog extends StatelessWidget {
  const QuranSourceDialog({super.key, required this.surah});

  final SurahText surah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final s = surah.source;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: styles.listSubtitle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(value, style: styles.listTitle.copyWith(fontSize: 14)),
        ],
      ),
    );
    return AlertDialog(
      title: Text(l10n.sourceDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            row(
              l10n.sourceLabel,
              l10n.sourceValue(s.name, s.script, s.version),
            ),
            row(l10n.linkLabel, s.homepage),
            row(l10n.numberingLabel, l10n.numberingHafsBasmala),
            row(l10n.checksLabel, l10n.checksText),
            row(
              l10n.reviewLabel,
              surah.reviewerSignedOff
                  ? l10n.reviewDone(surah.reviewer!, surah.reviewedAt!)
                  : l10n.reviewPending,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                l10n.licenceLabel,
                style: styles.listTitle.copyWith(fontSize: 14),
              ),
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    s.licence,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontFamily: AppFonts.latin,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: s.homepage));
            if (context.mounted) showUnavailable(context, l10n.linkCopied);
          },
          child: Text(l10n.copyLink),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

/// A persistent, honest label: the preview isn't Quran text.
class _PendingTextNotice extends StatelessWidget {
  const _PendingTextNotice({required this.dark, required this.onInfo});

  final bool dark;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final fg = dark ? Colors.white : ReaderColors.bar;
    return Material(
      color: dark ? const Color(0x2EFFFFFF) : const Color(0x1420474C),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onInfo,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.quranTextPendingTitle,
                    style: styles.noticeTitle.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
