import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/localized_digits.dart';
import '../../../core/text/search_folding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/quran_metadata_repository.dart';
import '../data/quran_text_repository.dart';
import '../domain/quran_metadata.dart';
import '../domain/quran_text_availability.dart';

/// One searchable ayah: the text exactly as shown, plus a folded key used
/// only for matching (QURAN_AND_AUDIO_ACCURACY §3.1).
@immutable
class SearchableAyah {
  const SearchableAyah(this.surah, this.ayah, this.text, this.key);

  final int surah;
  final int ayah;
  final String text;
  final String key;
}

/// Every verified ayah, loaded once. Surahs that fail verification are left
/// out (and counted), never shown.
final quranSearchCorpusProvider = FutureProvider<(List<SearchableAyah>, int)>((
  ref,
) async {
  final repo = ref.watch(quranTextRepositoryProvider);
  final out = <SearchableAyah>[];
  var failed = 0;
  for (var n = 1; n <= 114; n++) {
    final s = await repo.surah(n);
    if (s is! QuranTextVerified) {
      failed++;
      continue;
    }
    for (final a in s.surah.ayahs) {
      out.add(
        SearchableAyah(
          n,
          a.number,
          a.displayText,
          foldForSearch(a.displayText),
        ),
      );
    }
  }
  return (List<SearchableAyah>.unmodifiable(out), failed);
});

/// Matches [query] against the folded keys. Needs at least 2 folded
/// characters; returns at most [limit] results in Quran order.
List<SearchableAyah> searchQuran(
  List<SearchableAyah> corpus,
  String query, {
  int limit = 200,
}) {
  final q = foldForSearch(query);
  if (q.length < 2) return const [];
  final out = <SearchableAyah>[];
  for (final a in corpus) {
    if (a.key.contains(q)) {
      out.add(a);
      if (out.length >= limit) break;
    }
  }
  return out;
}

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
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
    final styles = context.text;
    final locale = Localizations.localeOf(context);
    final arabicUi = locale.languageCode == 'ar';
    final corpus = ref.watch(quranSearchCorpusProvider);
    final meta = ref.watch(quranMetadataProvider).value;
    final metadata = meta is QuranMetadataAvailable ? meta.metadata : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ReaderColors.surface,
        appBar: AppBar(
          backgroundColor: ReaderColors.bar,
          foregroundColor: ReaderColors.onBar,
          title: Text(
            l10n.quranSearchTitle,
            style: styles.appBarTitle.copyWith(fontSize: 17),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const ValueKey('quran-search-field'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.quranSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: corpus.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Text(l10n.libraryLoadError, style: styles.body),
                ),
                data: (data) {
                  final (all, failed) = data;
                  final results = searchQuran(all, _query);
                  final folded = foldForSearch(_query);
                  if (folded.length < 2) {
                    return _Hint(text: l10n.quranSearchMinChars);
                  }
                  if (results.isEmpty) {
                    return _Hint(text: l10n.noSearchResults);
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          18,
                          4,
                          18,
                          4,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            localizeDigits(
                              results.length >= 200
                                  ? l10n.quranSearchManyResults('200')
                                  : l10n.quranSearchResults(
                                      '${results.length}',
                                    ),
                              locale,
                            ),
                            style: styles.listSubtitle,
                          ),
                        ),
                      ),
                      if (failed > 0)
                        Text(
                          l10n.quranSearchSkipped('$failed'),
                          style: styles.listSubtitle,
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final r = results[i];
                            final s = metadata?.surah(r.surah);
                            final name = s == null
                                ? ''
                                : (arabicUi
                                      ? s.nameArabic
                                      : s.nameTransliterated);
                            return InkWell(
                              key: ValueKey('result-${r.surah}:${r.ayah}'),
                              onTap: () => context.push(
                                AppRoutes.quranAt(r.surah, r.ayah),
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  10,
                                  18,
                                  10,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: ReaderColors.divider,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      localizeDigits(
                                        '$name ${r.surah}:${r.ayah}',
                                        locale,
                                      ),
                                      style: styles.listSubtitle.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.text,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.quran,
                                        fontSize: 20,
                                        height: 1.9,
                                        color: ReaderColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.listSubtitle,
      ),
    ),
  );
}
