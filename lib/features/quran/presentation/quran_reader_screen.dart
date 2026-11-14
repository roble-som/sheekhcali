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
import '../data/quran_metadata_repository.dart';
import '../data/quran_text_repository.dart';
import '../domain/quran_metadata.dart';
import '../domain/quran_text_availability.dart';
import 'widgets/ayah_action_sheet.dart';
import 'widgets/mushaf_layout_preview.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_overflow_menu.dart';
import 'widgets/reading_controls.dart';
import 'widgets/surah_navigation.dart';
import 'widgets/surah_text_view.dart';

/// Quran reader (references 03–06, DESIGN_SYSTEM_SPECIFICATION §8.4 and §8.12).
///
/// Shows the approved, verified text (Tanzil Uthmani 1.1, C-25) either as
/// Madinah Mushaf pages (verified page boundaries; the app's own line layout,
/// since the printed layout's fonts are blocked on P-24) or as a whole surah,
/// with the Sheikh's Tafsir player on Al-Fatiha and verified ayah
/// highlighting. Text that fails verification is never shown.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({
    super.key,
    this.surah = 1,
    this.initialAyah,
    this.page,
  });

  final int surah;

  /// Open at this Mushaf page (wins over [surah] when page data exists).
  final int? page;

  /// Scroll to this ayah when the text first appears (index, juz, bookmark,
  /// search result or "continue reading").
  final int? initialAyah;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _moreKey = GlobalKey();
  bool _chromeVisible = true;
  Timer? _autoScroll;

  /// Where this reader opened (or, after a layout switch, where the reader
  /// was): resolved once the metadata is known.
  AyahRef? _target;

  /// The place being read now (page start, scroll position or tap).
  AyahRef? _place;

  // Whole-surah layout.
  final _scroll = ScrollController();
  final _textKey = GlobalKey<SurahTextViewState>();
  bool _didInitialScroll = false;

  // Page layout.
  PageController? _pageController;
  int? _currentPage;
  int? _initialPage;
  bool _turning = false;
  final _pageKeys = <int, GlobalKey<MushafPageState>>{};

  /// Long-pressed ayah (while its action sheet is open).
  AyahRef? _selected;

  /// The player was asked to prepare the recording (once per reader).
  bool _preloadRequested = false;

  @override
  void initState() {
    super.initState();
    // Verify (and on first use unpack) the Sheikh's recording in the
    // background now, not at the first tap. The provider runs it once.
    ref.read(fatihaRecordingProvider);
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _boundary?.cancel();
    _scroll.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _rememberPlace(AyahRef place) {
    _place = place;
    ref.read(lastReadProvider.notifier).set(place);
  }

  /// The reader's starting place: the requested page's first ayah, or the
  /// requested surah and ayah (ayah 1 if the ayah doesn't exist).
  AyahRef _resolveTarget(QuranMetadata? meta) {
    final existing = _target;
    if (existing != null) return existing;
    final page = widget.page;
    if (page != null && meta != null && meta.hasPages) {
      final seg = meta.pageSegments(page.clamp(1, meta.pageCount)).first;
      return _target = AyahRef(seg.surah, seg.firstAyah);
    }
    final ayah = widget.initialAyah ?? 1;
    final valid = meta == null || meta.isValid(widget.surah, ayah);
    return _target = AyahRef(widget.surah, valid ? ayah : 1);
  }

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
  bool _onScrollEnd(ScrollEndNotification n, int surah) {
    final viewport = _scroll.position.context.storageContext.findRenderObject();
    if (viewport is RenderBox) {
      final at =
          viewport.localToGlobal(const Offset(0, 0)) +
          Offset(viewport.size.width / 2, 40);
      final ayah = _textKey.currentState?.ayahAtGlobal(at);
      if (ayah != null) _rememberPlace(AyahRef(surah, ayah));
    }
    return false;
  }

  void _onPageChanged(QuranMetadata meta, int index) {
    final page = index + 1;
    if (page == _currentPage) return;
    _stopAutoScroll(keepTurning: true);
    setState(() => _currentPage = page);
    final first = meta.pageSegments(page).first;
    _rememberPlace(AyahRef(first.surah, first.firstAyah));
  }

  void _goToPage(int page, {bool animate = true}) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      c.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      c.jumpToPage(page - 1);
    }
  }

  /// Slow, steady scrolling for reading; any tap or the toolbar stops it. In
  /// the page layout it turns to the next page at the end of each page.
  void _toggleAutoScroll() {
    if (_autoScroll != null) {
      _stopAutoScroll();
      return;
    }
    showUnavailable(context, _l10n.autoScrollOn);
    _autoScroll = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final page = _currentPage;
      if (_pageController != null && page != null) {
        final scroll = _pageKeys[page]?.currentState?.scroll;
        if (_turning || scroll == null || !scroll.hasClients) return;
        final next = scroll.offset + 1.2;
        if (next < scroll.position.maxScrollExtent) {
          scroll.jumpTo(next);
          return;
        }
        final meta = ref.read(quranMetadataProvider).value;
        if (meta is! QuranMetadataAvailable ||
            page >= meta.metadata.pageCount) {
          _stopAutoScroll();
          return;
        }
        _turning = true;
        _pageController!
            .animateToPage(
              page,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            )
            .whenComplete(() => _turning = false);
        return;
      }
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

  void _stopAutoScroll({bool keepTurning = false}) {
    if (keepTurning && _turning) return;
    _autoScroll?.cancel();
    _autoScroll = null;
    if (mounted) setState(() {});
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  SpanIndex? get _index => ref.read(fatihaSpanIndexProvider).value;

  /// The ayah the user last tapped (to hear it explained, or just selected).
  AyahRef? _tapped;

  /// The segment playing because of that tap (reviewed, or an unreviewed
  /// candidate in review mode). Null once the user seeks elsewhere.
  AyahSegment? _segment;

  /// Plays the Sheikh's **explanation** of Al-Fatiha's [ayah] from the start
  /// of its segment, switching segments if something is already playing, and
  /// stops at the segment's end. With [withReading] ("Play Recitation +
  /// Tafsir"), the Sheikh's own reading of the ayah plays first, then the
  /// explanation.
  ///
  /// A reviewed span always wins over an AI-assisted candidate; candidates
  /// play in every build (owner decision C-31) and the player says their
  /// timing is not reviewed yet. With neither, nothing plays and the reader
  /// says so; never unrelated audio.
  Future<bool> _playExplanationFor(int ayah, {bool withReading = false}) async {
    _cancelBoundary();
    setState(() => _tapped = AyahRef(1, ayah));
    final recording = await ref.read(fatihaRecordingProvider.future);
    if (!mounted) return false;
    if (recording is! RecordingReady) {
      showUnavailable(context, switch (recording) {
        RecordingPlatformUnsupported() => _l10n.recordingPhoneOnly,
        RecordingNotPermitted() => _l10n.recordingNotInThisBuild,
        RecordingUnpackFailed() => _l10n.recordingUnpackFailed,
        _ => _l10n.unavailableRecording,
      });
      return false;
    }
    final reviewed = _index?.explanationForAyah(ayah);
    final candidates = await ref.read(fatihaCandidatesProvider.future);
    if (!mounted) return false;
    final candidate = reviewed == null
        ? candidates?.explanationForAyah(ayah)
        : null;
    var segment = reviewed != null
        ? AyahSegment.reviewed(ayah, reviewed)
        : candidate != null
        ? AyahSegment.candidate(ayah, candidate)
        : null;
    if (segment != null && withReading) {
      final reading = _index?.readingForAyah(ayah);
      final candidateReading = candidates?.readingForAyah(ayah);
      if (reading != null) {
        segment = segment.withReading(reading.startMs, reading.endMs);
      } else if (candidateReading != null) {
        segment = segment.withReading(
          candidateReading.startMs,
          candidateReading.endMs,
        );
      }
    }
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
    await player.seek(Duration(milliseconds: segment.playFromMs));
    await player.play();
    return true;
  }

  /// Fires at a segment boundary (end of the reading, end of the segment).
  /// Position updates arrive only every ~200 ms, so near a boundary a timer
  /// is set for the exact moment; the position checks are the fallback.
  Timer? _boundary;

  /// Jump this much before the reading ends, so the next ayah's first
  /// syllable is never heard.
  static const _jumpLeadMs = 80;

  /// Stop this much before the segment ends.
  static const _stopLeadMs = 40;

  void _cancelBoundary() {
    _boundary?.cancel();
    _boundary = null;
  }

  void _scheduleBoundary(int inMs, VoidCallback action) {
    _boundary?.cancel();
    _boundary = Timer(Duration(milliseconds: inMs < 0 ? 0 : inMs), () {
      _boundary = null;
      if (mounted) action();
    });
  }

  /// Reading done: pause, seek to the explanation, resume (no bleed).
  Future<void> _jumpToExplanation(AyahSegment segment) async {
    if (!identical(_segment, segment) || !segment.inReading) return;
    _cancelBoundary();
    final next = segment.readingDone();
    setState(() => _segment = next);
    final player = ref.read(tafsirPlayerProvider);
    await player.pause();
    await player.seek(Duration(milliseconds: next.startMs));
    if (identical(_segment, next)) await player.play();
  }

  void _finishSegment(AyahSegment segment) {
    if (!identical(_segment, segment) || segment.finished) return;
    _cancelBoundary();
    ref.read(tafsirPlayerProvider).pause();
    setState(() => _segment = segment.asFinished());
  }

  /// Stops at the end of the tapped ayah's segment, so a tap plays that
  /// explanation and not the rest of the lesson; after a reading, jumps to
  /// the explanation.
  void _onPlayback(TafsirPlaybackState? previous, TafsirPlaybackState next) {
    final segment = _segment;
    if (segment == null || !next.isPlaying) {
      if (!next.isPlaying) _cancelBoundary();
      return;
    }
    if (segment.finished) {
      // Play pressed after the segment ended: carry on through the lesson.
      setState(() {
        _segment = null;
        _tapped = null;
      });
      return;
    }
    final pos = next.position.inMilliseconds;
    if (segment.inReading) {
      final cut = segment.readingEndMs! - _jumpLeadMs;
      if (pos >= cut && pos < segment.readingEndMs! + 5000) {
        _jumpToExplanation(segment);
      } else if (pos >= segment.readingStartMs! && cut - pos <= 1500) {
        _scheduleBoundary(cut - pos, () => _jumpToExplanation(segment));
      }
      return;
    }
    final stopAt = segment.endMs - _stopLeadMs;
    if (pos >= stopAt && pos < segment.endMs + 5000) {
      _finishSegment(segment);
    } else if (pos >= segment.startMs && stopAt - pos <= 1500) {
      _scheduleBoundary(stopAt - pos, () => _finishSegment(segment));
    }
  }

  /// The user moved the playhead (slider or skip). Outside the tapped ayah's
  /// segment, the bar no longer plays "that ayah's explanation", so the
  /// highlight goes back to following reviewed spans only.
  void _onManualSeek(int targetMs) {
    _cancelBoundary();
    final segment = _segment;
    if (segment != null &&
        targetMs >= segment.startMs &&
        targetMs < segment.endMs) {
      if (segment.finished || segment.inReading) {
        setState(() => _segment = segment.restarted());
      }
      return;
    }
    if (_segment != null || _tapped != null) {
      setState(() {
        _segment = null;
        _tapped = null;
      });
    }
  }

  void _onAyahTap(AyahRef place) {
    _stopAutoScroll();
    _rememberPlace(place);
    if (place.surah == 1) {
      _playExplanationFor(place.ayah);
      return;
    }
    // The Sheikh's Tafsir recording exists for Al-Fatiha only: select the
    // ayah and say so, never play another surah's audio.
    setState(() => _tapped = _tapped == place ? null : place);
    showUnavailable(context, _l10n.noTafsirForSurah);
  }

  Future<void> _onAyahLongPress(SurahText surah, int ayah) async {
    HapticFeedback.selectionClick();
    _stopAutoScroll();
    final place = AyahRef(surah.number, ayah);
    _rememberPlace(place);
    setState(() => _selected = place);
    final action = await showAyahActionSheet(
      context,
      bookmarked: ref.read(bookmarksProvider).contains(place),
    );
    if (!mounted) return;
    setState(() => _selected = null);
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
        // The ayah as shown: exact stored text (without the basmala heading
        // the source prefixes to ayah 1 of most surahs), then its reference.
        await Clipboard.setData(
          ClipboardData(text: '${a.displayText}\n$reference'),
        );
        if (mounted) showUnavailable(context, _l10n.copiedAyah(reference));
      case AyahAction.playTafsir:
        if (surah.number == 1) {
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
      case AyahAction.playRecitationAndTafsir:
        if (surah.number == 1) {
          await _playExplanationFor(ayah, withReading: true);
        } else {
          showUnavailable(context, _l10n.noTafsirForSurah);
        }
      case AyahAction.playToEnd:
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
        final meta = ref.read(quranMetadataProvider).value;
        if (meta is! QuranMetadataAvailable || !meta.metadata.hasPages) {
          showUnavailable(context, _l10n.unavailableFeature);
          return;
        }
        final page = await showGoToPageDialog(
          context,
          pageCount: meta.metadata.pageCount,
          current: _currentPage,
        );
        if (!mounted || page == null) return;
        if (_pageController != null) {
          _goToPage(page, animate: false);
        } else {
          await context.push(AppRoutes.quranPage(page));
        }
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

  void _showSource(SurahText surah, {required bool pages}) {
    showDialog<void>(
      context: context,
      builder: (context) => QuranSourceDialog(surah: surah, pages: pages),
    );
  }

  /// Switching layout keeps the reader where it is.
  void _onLayoutChanged(QuranLayout? previous, QuranLayout next) {
    if (previous == next) return;
    _stopAutoScroll();
    setState(() {
      _target = _place ?? _target;
      _pageController?.dispose();
      _pageController = null;
      _currentPage = null;
      _initialPage = null;
      _didInitialScroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(readerDarkProvider);
    final index = ref.watch(fatihaSpanIndexProvider).value;
    final playback = ref.watch(tafsirPlaybackProvider).value;
    ref.listen(tafsirPlaybackProvider, (previous, next) {
      final value = next.value;
      if (value != null) _onPlayback(previous?.value, value);
    });
    ref.listen(quranLayoutProvider, _onLayoutChanged);
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
    final marks = <AyahRef, AyahMark>{};
    if (playback != null && playback.phase != TafsirPhase.idle) {
      final span = activeSpanAt(index, playback.position.inMilliseconds);
      if (span != null) {
        for (final n in span.ayahs) {
          marks[AyahRef(1, n)] = markForKind(span.kind);
        }
      }
    }
    final tapped = _tapped;
    if (tapped != null && marks.isEmpty) marks[tapped] = AyahMark.selected;
    if (_selected != null) marks[_selected!] = AyahMark.selected;

    final fontSize = ref.watch(quranFontSizeProvider);
    final metaAsync = ref.watch(quranMetadataProvider);
    final metaValue = metaAsync.value;
    final meta = metaValue is QuranMetadataAvailable
        ? metaValue.metadata
        : null;
    final usePages =
        meta != null &&
        meta.hasPages &&
        ref.watch(quranLayoutProvider) == QuranLayout.pages;

    final Widget body;
    final bool fatihaShown;
    if (metaAsync.isLoading) {
      body = Center(
        child: CircularProgressIndicator(
          color: dark ? HomeColors.goldLabel : ReaderColors.icon,
        ),
      );
      fatihaShown = false;
    } else if (usePages) {
      final target = _resolveTarget(meta);
      final initialPage = _initialPage ??= meta.pageOf(
        target.surah,
        target.ayah,
      )!;
      final controller = _pageController ??= PageController(
        initialPage: initialPage - 1,
      );
      final current = _currentPage ??= initialPage;
      if (_place == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _place == null) _rememberPlace(target);
        });
      }
      body = _buildPages(
        meta,
        controller,
        target,
        initialPage,
        marks,
        dark,
        fontSize,
      );
      fatihaShown = meta.pageSegments(current).any((s) => s.surah == 1);
    } else {
      final target = _resolveTarget(meta);
      final text = ref.watch(surahTextProvider(target.surah));
      final verified = text.value is QuranTextVerified
          ? (text.value! as QuranTextVerified).surah
          : null;
      if (verified != null && !_didInitialScroll) {
        _didInitialScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (target.ayah > 1) _scrollToAyah(target.ayah);
          _rememberPlace(target);
        });
      }
      body = _buildSurah(text, target.surah, marks, dark, fontSize, meta);
      fatihaShown = verified != null && verified.number == 1;
    }

    // On Al-Fatiha's page, prepare the player as soon as the recording is
    // verified, so the first tap plays at once.
    final recording = ref.watch(fatihaRecordingProvider).value;
    if (fatihaShown && !_preloadRequested && recording is RecordingReady) {
      _preloadRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(tafsirPlayerProvider)
            .preload(
              path: recording.path,
              title: _l10n.tafsirTitle,
              artist: _l10n.speakerName,
            );
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
                Expanded(child: body),
                if (fatihaShown)
                  TafsirPlayerBar(
                    index: index,
                    selectedAyah: _tapped?.surah == 1 ? _tapped!.ayah : null,
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

  /// The Madinah Mushaf pages, swiped right to left as in a printed Mushaf
  /// (the next page comes from the left), whatever the interface language.
  Widget _buildPages(
    QuranMetadata meta,
    PageController controller,
    AyahRef target,
    int initialPage,
    Map<AyahRef, AyahMark> marks,
    bool dark,
    double fontSize,
  ) {
    final uiDirection = Directionality.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _stopAutoScroll();
        setState(() => _chromeVisible = !_chromeVisible);
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          key: const ValueKey('mushaf-pages'),
          controller: controller,
          itemCount: meta.pageCount,
          onPageChanged: (i) => _onPageChanged(meta, i),
          itemBuilder: (context, i) {
            final page = i + 1;
            return Directionality(
              textDirection: uiDirection,
              child: MushafPage(
                key: _pageKeys.putIfAbsent(
                  page,
                  GlobalKey<MushafPageState>.new,
                ),
                page: page,
                metadata: meta,
                dark: dark,
                marks: marks,
                fontSize: fontSize,
                initialAyah: page == initialPage ? target : null,
                onAyahTap: _onAyahTap,
                onAyahLongPress: _onAyahLongPress,
                onSourceTap: (s) => _showSource(s, pages: true),
                onPlaceSettled: _rememberPlace,
                onPrevious: page > 1 ? () => _goToPage(page - 1) : null,
                onNext: page < meta.pageCount
                    ? () => _goToPage(page + 1)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// One whole surah as continuous text, with next/previous surah links.
  Widget _buildSurah(
    AsyncValue<QuranTextAvailability> text,
    int surahNumber,
    Map<AyahRef, AyahMark> marks,
    bool dark,
    double fontSize,
    QuranMetadata? meta,
  ) {
    return text.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: dark ? HomeColors.goldLabel : ReaderColors.icon,
        ),
      ),
      error: (e, s) => _Preview(
        dark: dark,
        selected: _selected?.ayah,
        onInfo: _showPendingInfo,
        onToggleChrome: () => setState(() => _chromeVisible = !_chromeVisible),
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
            onNotification: (n) => _onScrollEnd(n, surah.number),
            child: Center(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SurahTextView(
                        key: _textKey,
                        surah: surah,
                        dark: dark,
                        marks: {
                          for (final e in marks.entries)
                            if (e.key.surah == surah.number)
                              e.key.ayah: e.value,
                        },
                        fontSize: fontSize,
                        onAyahTap: (n) => _onAyahTap(AyahRef(surah.number, n)),
                        onAyahLongPress: (n) => _onAyahLongPress(surah, n),
                        onSourceTap: () => _showSource(
                          surah,
                          pages: meta != null && meta.hasPages,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SurahNavigation(surah: surah.number, dark: dark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        QuranTextUnavailable() => _Preview(
          dark: dark,
          selected: _selected?.ayah,
          onInfo: _showPendingInfo,
          onToggleChrome: () =>
              setState(() => _chromeVisible = !_chromeVisible),
          onLongPress: (n) async {
            setState(() => _selected = AyahRef(surahNumber, n));
            await showAyahActionSheet(context);
            if (!mounted) return;
            setState(() => _selected = null);
            showUnavailable(context, _l10n.unavailableQuranText);
          },
        ),
      },
    );
  }
}

/// Asks for a Mushaf page number (1–[pageCount]); null if cancelled.
Future<int?> showGoToPageDialog(
  BuildContext context, {
  required int pageCount,
  int? current,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) =>
        _GoToPageDialog(pageCount: pageCount, current: current),
  );
}

class _GoToPageDialog extends StatefulWidget {
  const _GoToPageDialog({required this.pageCount, this.current});

  final int pageCount;
  final int? current;

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Accepts Western and Arabic-Indic digits.
  int? _parse(String raw) {
    final western = String.fromCharCodes(
      raw.trim().runes.map(
        (r) => r >= 0x0660 && r <= 0x0669
            ? r - 0x0660 + 0x30
            : (r >= 0x06F0 && r <= 0x06F9 ? r - 0x06F0 + 0x30 : r),
      ),
    );
    return int.tryParse(western);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final n = _parse(_controller.text);
    if (n == null || n < 1 || n > widget.pageCount) {
      setState(
        () => _error = localizeDigits(
          l10n.goToPageInvalid('1', '${widget.pageCount}'),
          locale,
        ),
      );
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return AlertDialog(
      title: Text(l10n.goToPageTitle),
      content: TextField(
        key: const ValueKey('go-to-page-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: localizeDigits(
            l10n.goToPageHint('1', '${widget.pageCount}'),
            locale,
          ),
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('go-to-page-submit'),
          onPressed: _submit,
          child: Text(l10n.goToPageAction),
        ),
      ],
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
  const QuranSourceDialog({super.key, required this.surah, this.pages = false});

  final SurahText surah;

  /// Whether to describe the page boundaries (page data is installed).
  final bool pages;

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
            if (pages) row(l10n.pagesLabel, l10n.pagesSourceValue),
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
