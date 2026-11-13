import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../core/l10n/localized_digits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/content_badge.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';
import '../data/library_repository.dart';
import '../domain/book.dart';
import 'library_labels.dart';
import 'library_screen.dart' show bookBadges;
import 'widgets/book_cover.dart';

/// Book details (concept 7, DESIGN_SYSTEM_SPECIFICATION §8.7).
/// Unknown metadata reads "Not recorded"; nothing is guessed.
class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final book = ref.watch(bookProvider(bookId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: HomeColors.bg,
        appBar: AppBar(
          backgroundColor: HomeColors.bg,
          foregroundColor: HomeColors.green900,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: book.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(l10n.bookNotFound)),
          data: (b) => b == null
              ? Center(child: Text(l10n.bookNotFound, style: context.text.body))
              : _Details(book: b),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final styles = context.text;
    final rtlTitle = Bidi.detectRtlDirectionality(book.title);

    Widget field(String label, String? value) => Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: styles.listSubtitle.copyWith(color: HomeColors.textMuted),
          children: [
            TextSpan(
              text: value ?? l10n.notRecorded,
              style: TextStyle(
                fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
                color: value == null ? HomeColors.textMuted : HomeColors.text,
              ),
            ),
          ],
        ),
      ),
    );

    String? count(int? n) => n == null ? null : localizeDigits('$n', locale);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (book.isPreview)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ContentBadge(
              label: l10n.previewBanner,
              icon: Icons.visibility_outlined,
              tone: BadgeTone.preview,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(book: book, width: 96, height: 136),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      book.title,
                      textDirection: rtlTitle
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: styles.title.copyWith(
                        fontFamily: rtlTitle ? AppFonts.arabicUi : null,
                      ),
                    ),
                  ),
                  if (book.titleEnglish != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.titleEnglish!,
                      textDirection: TextDirection.ltr,
                      style: styles.listSubtitle,
                    ),
                  ],
                  const SizedBox(height: 10),
                  field(l10n.fieldAuthor, book.author),
                  field(l10n.fieldCategory, categoryLabel(l10n, book.category)),
                  field(
                    l10n.fieldLanguage,
                    languageLabel(l10n, book.languageCode),
                  ),
                  field(l10n.fieldEdition, book.edition),
                  field(l10n.fieldPublisher, book.publisher),
                  field(
                    l10n.fieldVolumes,
                    book.volumes.isEmpty ? null : count(book.volumes.length),
                  ),
                  field(l10n.fieldPages, count(book.pageCount)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 6, children: bookBadges(l10n, book)),
        const SizedBox(height: 18),
        _Actions(
          onRead: () => showUnavailable(context, l10n.unavailableFeature),
          onDownload: () => showUnavailable(context, l10n.unavailableFeature),
        ),
        if (book.volumes.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionLabel(l10n.sectionContents),
          const SizedBox(height: 12),
          for (final v in book.volumes) _VolumeCard(volume: v),
        ],
        const SizedBox(height: 24),
        SectionLabel(l10n.sectionRights),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                book.rightsRecorded ? Icons.verified_outlined : Icons.gavel,
                size: 20,
                color: book.rightsRecorded
                    ? SemanticColors.verified
                    : SemanticColors.draft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  book.rightsRecorded
                      ? l10n.rightsRecordedText
                      : l10n.rightsNotRecorded,
                  style: styles.listSubtitle.copyWith(
                    color: HomeColors.text,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({required this.volume});

  final BookVolume volume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final styles = context.text;
    final title =
        volume.title ??
        l10n.volumeTitle(localizeDigits('${volume.number}', locale));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 6),
            child: Text(
              title,
              style: styles.listTitle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final c in volume.chapters)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ReaderColors.divider)),
              ),
              child: Row(
                children: [
                  Icon(
                    c.lessonCount > 0
                        ? Icons.play_circle_outline
                        : Icons.article_outlined,
                    size: 20,
                    color: ReaderColors.icon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.title ??
                          l10n.chapterTitle(
                            localizeDigits('${c.number}', locale),
                          ),
                      style: styles.listTitle,
                    ),
                  ),
                  Text(
                    localizeDigits(l10n.lessonCount(c.lessonCount), locale),
                    style: styles.listSubtitle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Read and Download. Side by side normally; stacked at large text sizes so
/// the labels never clip.
class _Actions extends StatelessWidget {
  const _Actions({required this.onRead, required this.onDownload});

  final VoidCallback onRead;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final read = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: HomeColors.green900,
        minimumSize: const Size.fromHeight(48),
        shape: shape,
      ),
      onPressed: onRead,
      icon: const Icon(Icons.auto_stories),
      label: Text(l10n.actionRead),
    );
    final download = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: HomeColors.green900,
        backgroundColor: HomeColors.surface,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0xFFCFD3CE)),
        shape: shape,
      ),
      onPressed: onDownload,
      icon: const Icon(Icons.download),
      label: Text(l10n.actionDownload),
    );
    final large = MediaQuery.textScalerOf(context).scale(10) / 10 > 1.3;
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [read, const SizedBox(height: 10), download],
      );
    }
    return Row(
      children: [
        Expanded(child: read),
        const SizedBox(width: 10),
        Expanded(child: download),
      ],
    );
  }
}
