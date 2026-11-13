import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/localized_digits.dart';
import '../../../core/text/search_folding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/placeholder_box.dart';
import '../../../l10n/app_localizations.dart';
import '../data/quran_metadata_repository.dart';
import '../domain/quran_metadata.dart';
import 'widgets/bookmarks_list.dart';

/// Surah and Juz navigation (concept 5, DESIGN_SYSTEM_SPECIFICATION §8.5).
///
/// It lists only verified metadata. Until the source is approved and imported
/// (P-03, Phase 3A) it shows an honest notice and a labelled layout preview.
class QuranIndexScreen extends ConsumerWidget {
  const QuranIndexScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final metadata = ref.watch(quranMetadataProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab.clamp(0, 2),
        child: Scaffold(
          backgroundColor: ReaderColors.surface,
          appBar: AppBar(
            backgroundColor: ReaderColors.bar,
            foregroundColor: ReaderColors.onBar,
            title: Text(
              l10n.quranCardTitle,
              style: styles.appBarTitle.copyWith(fontSize: 17),
            ),
            bottom: TabBar(
              indicatorColor: HomeColors.gold,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: ReaderColors.onBar,
              unselectedLabelColor: const Color(0xB3FFFFFF),
              labelStyle: styles.noticeTitle.copyWith(fontSize: 14),
              unselectedLabelStyle: styles.noticeTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: l10n.tabSurah),
                Tab(text: l10n.tabJuz),
                Tab(text: l10n.tabBookmarks),
              ],
            ),
          ),
          body: metadata.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _ErrorState(
              onRetry: () => ref.invalidate(quranMetadataProvider),
            ),
            data: (availability) => switch (availability) {
              QuranMetadataUnavailable() => const TabBarView(
                children: [
                  _UnavailableIndex(),
                  _UnavailableIndex(),
                  BookmarksList(metadata: null),
                ],
              ),
              QuranMetadataAvailable(:final metadata) => TabBarView(
                children: [
                  _SurahList(metadata: metadata),
                  _JuzList(metadata: metadata),
                  BookmarksList(metadata: metadata),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.libraryLoadError, style: context.text.body),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Notice plus hatched preview rows. Nothing in it is Quran metadata.
class _UnavailableIndex extends StatelessWidget {
  const _UnavailableIndex();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5E3E4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: ReaderColors.icon,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.indexUnavailableTitle,
                      style: styles.listTitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ReaderColors.icon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.indexUnavailableBody,
                      style: styles.listSubtitle.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 4),
          child: Text(
            l10n.layoutPreviewLabel,
            style: styles.listSubtitle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        for (var i = 0; i < 6; i++) const _PreviewRow(),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ReaderColors.divider)),
      ),
      child: const Row(
        children: [
          PlaceholderBox(width: 36, height: 36, circle: true),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlaceholderBox(width: 150, height: 13, radius: 3),
                SizedBox(height: 7),
                PlaceholderBox(width: 110, height: 10, radius: 3),
              ],
            ),
          ),
          PlaceholderBox(width: 70, height: 20, radius: 3),
        ],
      ),
    );
  }
}

/// Number inside a ring, in the ayah-marker green of reference 03.
class _NumberRing extends StatelessWidget {
  const _NumberRing(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ReaderColors.ayahMarker, width: 1.6),
      ),
      child: Text(
        localizeDigits('$number', locale),
        style: context.text.listSubtitle.copyWith(
          color: ReaderColors.icon,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.indexSearchHint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF4F5F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SurahList extends StatefulWidget {
  const _SurahList({required this.metadata});

  final QuranMetadata metadata;

  @override
  State<_SurahList> createState() => _SurahListState();
}

class _SurahListState extends State<_SurahList> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(SurahInfo s) {
    if (_query.isEmpty) return true;
    final q = foldForSearch(_query);
    return '${s.number}' == q ||
        foldForSearch(s.nameTransliterated).contains(q) ||
        foldForSearch(s.nameEnglish).contains(q) ||
        foldForSearch(s.nameArabic).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final styles = context.text;
    final arabicUi = styles.isArabic;
    final items = widget.metadata.surahs.where(_matches).toList();
    return Column(
      children: [
        _SearchField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(l10n.noSearchResults, style: styles.listSubtitle),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final s = items[i];
                    final place = s.revelation == RevelationPlace.makki
                        ? l10n.revelationMakki
                        : l10n.revelationMadani;
                    final details = localizeDigits(
                      arabicUi
                          ? '$place · ${l10n.ayahCount(s.ayahCount)}'
                          : '${s.nameEnglish} · $place · ${l10n.ayahCount(s.ayahCount)}',
                      locale,
                    );
                    final title = arabicUi
                        ? s.nameArabic
                        : s.nameTransliterated;
                    return Semantics(
                      button: true,
                      label: l10n.surahRowSemantics(
                        localizeDigits('${s.number}', locale),
                        title,
                        details,
                      ),
                      excludeSemantics: true,
                      child: InkWell(
                        key: ValueKey('surah-row-${s.number}'),
                        onTap: () => context.push(AppRoutes.quranAt(s.number)),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: ReaderColors.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              _NumberRing(s.number),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: styles.listTitle.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(details, style: styles.listSubtitle),
                                  ],
                                ),
                              ),
                              if (!arabicUi) ...[
                                const SizedBox(width: 12),
                                Text(
                                  s.nameArabic,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: AppFonts.arabicContent,
                                    fontSize: 20,
                                    color: ReaderColors.text,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _JuzList extends StatefulWidget {
  const _JuzList({required this.metadata});

  final QuranMetadata metadata;

  @override
  State<_JuzList> createState() => _JuzListState();
}

class _JuzListState extends State<_JuzList> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final styles = context.text;
    final q = foldForSearch(_query);
    final items = widget.metadata.juzs
        .where((j) => q.isEmpty || '${j.number}' == q)
        .toList();
    return Column(
      children: [
        _SearchField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(l10n.noSearchResults, style: styles.listSubtitle),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final j = items[i];
                    final surah = widget.metadata.surah(j.startSurah);
                    final surahName = surah == null
                        ? ''
                        : (styles.isArabic
                              ? surah.nameArabic
                              : surah.nameTransliterated);
                    final title = l10n.juzTitle(
                      localizeDigits('${j.number}', locale),
                    );
                    final subtitle = l10n.juzStartsAt(
                      surahName,
                      localizeDigits('${j.startSurah}:${j.startAyah}', locale),
                    );
                    return Semantics(
                      button: true,
                      label: '$title. $subtitle',
                      excludeSemantics: true,
                      child: InkWell(
                        key: ValueKey('juz-row-${j.number}'),
                        onTap: () => context.push(
                          AppRoutes.quranAt(j.startSurah, j.startAyah),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: ReaderColors.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              _NumberRing(j.number),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: styles.listTitle.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(subtitle, style: styles.listSubtitle),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
