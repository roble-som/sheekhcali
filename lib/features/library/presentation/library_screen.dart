import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../app/router.dart';
import '../../../core/text/search_folding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/content_badge.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/domain/app_destination.dart';
import '../../navigation/presentation/app_drawer.dart';
import '../../navigation/presentation/drawer_back_scope.dart';
import '../data/library_repository.dart';
import '../domain/book.dart';
import 'library_labels.dart';
import 'widgets/book_cover.dart';

/// Library filter: everything, the Sheikh's collection, or one category.
sealed class LibraryFilter {
  const LibraryFilter();
}

final class AllBooksFilter extends LibraryFilter {
  const AllBooksFilter();
}

final class SheikhBooksFilter extends LibraryFilter {
  const SheikhBooksFilter();
}

final class CategoryFilter extends LibraryFilter {
  const CategoryFilter(this.category);

  final BookCategory category;
}

/// Islamic book library (concept 6, DESIGN_SYSTEM_SPECIFICATION §8.6).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  LibraryFilter _filter = const AllBooksFilter();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Book b) {
    final f = _filter;
    final inFilter = switch (f) {
      AllBooksFilter() => true,
      SheikhBooksFilter() => b.collection == CollectionType.sheikhOfficial,
      CategoryFilter(:final category) => b.category == category,
    };
    if (!inFilter) return false;
    if (_query.isEmpty) return true;
    final q = foldForSearch(_query);
    return foldForSearch(b.title).contains(q) ||
        foldForSearch(b.titleEnglish ?? '').contains(q) ||
        foldForSearch(b.author ?? '').contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final books = ref.watch(libraryBooksProvider);
    final canPop = context.canPop();

    final chips = <(String, LibraryFilter)>[
      (l10n.categoryAll, const AllBooksFilter()),
      (l10n.categorySheikh, const SheikhBooksFilter()),
      for (final c in BookCategory.values)
        (categoryLabel(l10n, c), CategoryFilter(c)),
    ];

    bool selected(LibraryFilter f) => switch ((f, _filter)) {
      (AllBooksFilter(), AllBooksFilter()) => true,
      (SheikhBooksFilter(), SheikhBooksFilter()) => true,
      (CategoryFilter(category: final a), CategoryFilter(category: final b)) =>
        a == b,
      _ => false,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: DrawerBackScope(
        scaffoldKey: _scaffoldKey,
        builder: (context, onDrawerChanged) => Scaffold(
          key: _scaffoldKey,
          onDrawerChanged: onDrawerChanged,
          backgroundColor: HomeColors.bg,
          drawer: const AppDrawer(current: AppDestination.library),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 24, 0),
                    child: Row(
                      children: [
                        if (canPop)
                          BackButton(color: HomeColors.green900)
                        else
                          HamburgerButton(
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(l10n.libraryTitle, style: styles.title),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      8,
                      AppSpacing.gutter,
                      12,
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.librarySearchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: HomeColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFDADDD8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: HomeColors.green900,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final (label, filter) = chips[i];
                        final on = selected(filter);
                        return Center(
                          child: ChoiceChip(
                            label: Text(label),
                            selected: on,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = filter),
                            labelStyle: styles.listSubtitle.copyWith(
                              color: on ? Colors.white : HomeColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                            selectedColor: HomeColors.green900,
                            backgroundColor: HomeColors.surface,
                            side: BorderSide(
                              color: on
                                  ? HomeColors.green900
                                  : const Color(0xFFCFD3CE),
                            ),
                            shape: const StadiumBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ...books.when(
                  loading: () => [const _SkeletonSliver()],
                  error: (e, s) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Message(
                        icon: Icons.error_outline,
                        title: l10n.libraryLoadError,
                        action: OutlinedButton(
                          onPressed: () => ref.invalidate(libraryBooksProvider),
                          child: Text(l10n.retry),
                        ),
                      ),
                    ),
                  ],
                  data: (all) => _content(context, all),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 24 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<Book> all) {
    final l10n = AppLocalizations.of(context);
    if (all.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.local_library_outlined,
            title: l10n.libraryEmptyTitle,
            body: l10n.libraryEmptyBody,
          ),
        ),
      ];
    }
    final visible = all.where(_matches).toList();
    final showShelf = _filter is AllBooksFilter && _query.isEmpty;
    final shelf = all
        .where((b) => b.collection == CollectionType.sheikhOfficial)
        .toList();
    return [
      if (all.any((b) => b.isPreview))
        SliverToBoxAdapter(child: _PreviewBanner(text: l10n.previewBanner)),
      if (visible.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(icon: Icons.search_off, title: l10n.libraryNoResults),
        )
      else ...[
        if (showShelf && shelf.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.gutter + 3,
              14,
              AppSpacing.gutter,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionLabel(l10n.sectionSheikhBooks),
            ),
          ),
          // Sized by its content (not a fixed height) so badges and large
          // text never overflow. The shelf holds one collection, so building
          // it eagerly is fine.
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < shelf.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _ShelfItem(book: shelf[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter + 3,
            14,
            AppSpacing.gutter,
            12,
          ),
          sliver: SliverToBoxAdapter(child: SectionLabel(l10n.sectionAllBooks)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => BookRow(book: visible[i]),
          ),
        ),
      ],
    ];
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        8,
        AppSpacing.gutter,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6C77A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 18,
            color: Color(0xFF6A4E12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.text.listSubtitle.copyWith(
                color: const Color(0xFF6A4E12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final styles = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: HomeColors.greenChip),
          const SizedBox(height: 14),
          Text(
            title,
            style: styles.title.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              style: styles.body.copyWith(color: HomeColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _SkeletonSliver extends StatelessWidget {
  const _SkeletonSliver();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFDDDFDB),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        16,
        AppSpacing.gutter,
        0,
      ),
      sliver: SliverList.list(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  bar(52, 72),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(160, 14),
                      const SizedBox(height: 8),
                      bar(110, 11),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: book.title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(AppRoutes.book(book.id)),
        child: SizedBox(
          // Grows with large text so the badges (above all "Preview") never
          // truncate.
          width:
              88 *
              MediaQuery.textScalerOf(context).scale(10).clamp(10, 18) /
              10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(book: book, width: 88, height: 124),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (book.isPreview)
                    ContentBadge(
                      label: l10n.previewBadge,
                      icon: Icons.visibility_outlined,
                      tone: BadgeTone.preview,
                    ),
                  if (book.hasAudio)
                    ContentBadge(
                      label: l10n.badgeAudio,
                      icon: Icons.headphones,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A book in the all-books list.
class BookRow extends StatelessWidget {
  const BookRow({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final rtlTitle = Bidi.detectRtlDirectionality(book.title);
    final subtitle = [
      book.author ?? l10n.notRecorded,
      categoryLabel(l10n, book.category),
      languageLabel(l10n, book.languageCode),
    ].join(' · ');
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      button: true,
      label: '${book.title}. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: HomeColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.push(AppRoutes.book(book.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(book: book, width: 52, height: 72, showTitle: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        textDirection: rtlTitle
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: styles.tileTitle.copyWith(
                          fontSize: 16,
                          fontFamily: rtlTitle ? AppFonts.arabicUi : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: styles.listSubtitle.copyWith(
                          color: HomeColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: bookBadges(l10n, book, compact: true),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(Icons.chevron_right, color: HomeColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badges shown for a book: what exists, and what is still pending.
///
/// [compact] (list rows) leaves out the "missing" details (no transcript, not
/// synced), which Book details still shows, so rows stay calm.
List<Widget> bookBadges(
  AppLocalizations l10n,
  Book book, {
  bool compact = false,
}) => [
  if (book.isPreview)
    ContentBadge(
      label: l10n.previewBadge,
      icon: Icons.visibility_outlined,
      tone: BadgeTone.preview,
    ),
  if (book.hasAudio)
    ContentBadge(label: l10n.badgeAudio, icon: Icons.headphones),
  if (!compact && book.hasAudio && !book.hasTranscript)
    ContentBadge(
      label: l10n.badgeNoTranscript,
      icon: Icons.pending_outlined,
      tone: BadgeTone.pending,
    ),
  if (book.hasTranscript)
    ContentBadge(label: l10n.badgeTranscript, icon: Icons.subject),
  if (!compact && book.hasAudio && !book.isSynced)
    ContentBadge(
      label: l10n.badgeNotSynced,
      icon: Icons.sync_disabled,
      tone: BadgeTone.pending,
    ),
  if (book.isSynced)
    ContentBadge(
      label: l10n.badgeSynced,
      icon: Icons.sync,
      tone: BadgeTone.positive,
    ),
  if (book.isDownloaded)
    ContentBadge(
      label: l10n.badgeDownloaded,
      icon: Icons.offline_pin,
      tone: BadgeTone.positive,
    ),
  if (book.status == ContentStatus.needsVerification)
    ContentBadge(
      label: l10n.badgeNeedsVerification,
      icon: Icons.rule,
      tone: BadgeTone.pending,
    ),
];
