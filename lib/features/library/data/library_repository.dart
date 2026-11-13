import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/book.dart';

abstract interface class LibraryRepository {
  Future<List<Book>> books();
  Future<Book?> book(String id);
}

/// The shipped catalogue. In Phase 2 it reads published books from Drift
/// `content.db`. **Nothing is published yet** (CONTENT_INVENTORY), so it is
/// empty, and the Library shows its honest empty state.
class PublishedLibraryRepository implements LibraryRepository {
  const PublishedLibraryRepository();

  @override
  Future<List<Book>> books() async => const [];

  @override
  Future<Book?> book(String id) async => null;
}

/// **Design preview data for debug builds only.** It lets the Library and
/// Book details screens be reviewed with content-shaped placeholders. Every
/// title says "Preview book", every unknown field is null ("Not recorded"),
/// and it holds no religious text of any kind. Release builds can't enable it
/// (see [designPreviewProvider]).
class DesignPreviewLibraryRepository implements LibraryRepository {
  const DesignPreviewLibraryRepository();

  static const _books = <Book>[
    Book(
      id: 'preview-1',
      title: 'كتاب معاينة ١',
      titleEnglish: 'Preview book 1',
      category: BookCategory.tafsir,
      collection: CollectionType.sheikhOfficial,
      languageCode: 'ar',
      status: ContentStatus.needsVerification,
      hasAudio: true,
      volumes: [
        BookVolume(
          number: 1,
          chapters: [
            BookChapter(number: 1, lessonCount: 2),
            BookChapter(number: 2, lessonCount: 1),
            BookChapter(number: 3),
          ],
        ),
        BookVolume(number: 2, chapters: [BookChapter(number: 1)]),
      ],
      isPreview: true,
    ),
    Book(
      id: 'preview-2',
      title: 'كتاب معاينة ٢',
      titleEnglish: 'Preview book 2',
      category: BookCategory.arabicLanguage,
      collection: CollectionType.sheikhOfficial,
      languageCode: 'ar',
      status: ContentStatus.needsVerification,
      hasAudio: true,
      hasTranscript: true,
      volumes: [
        BookVolume(
          number: 1,
          chapters: [BookChapter(number: 1, lessonCount: 1)],
        ),
      ],
      isPreview: true,
    ),
    Book(
      id: 'preview-3',
      title: 'كتاب معاينة ٣',
      titleEnglish: 'Preview book 3',
      category: BookCategory.fiqh,
      collection: CollectionType.sheikhOfficial,
      languageCode: 'ar',
      status: ContentStatus.needsVerification,
      isPreview: true,
    ),
    Book(
      id: 'preview-4',
      title: 'كتاب معاينة ٤',
      category: BookCategory.hadith,
      collection: CollectionType.islamicOther,
      languageCode: 'ar',
      status: ContentStatus.needsVerification,
      isPreview: true,
    ),
    Book(
      id: 'preview-5',
      title: 'Preview book 5',
      category: BookCategory.seerah,
      collection: CollectionType.islamicOther,
      languageCode: 'so',
      status: ContentStatus.needsVerification,
      isPreview: true,
    ),
    Book(
      id: 'preview-6',
      title: 'Preview book 6',
      category: BookCategory.education,
      collection: CollectionType.islamicOther,
      languageCode: 'en',
      status: ContentStatus.needsVerification,
      isPreview: true,
    ),
  ];

  @override
  Future<List<Book>> books() async => _books;

  @override
  Future<Book?> book(String id) async {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// Debug-only switch for the design preview catalogue. Always false in
/// release and profile builds, whatever is stored.
class DesignPreviewController extends Notifier<bool> {
  static const _key = 'debug.designPreview';

  @override
  bool build() =>
      kDebugMode &&
      (ref.watch(sharedPreferencesProvider).getBool(_key) ?? false);

  Future<void> set({required bool enabled}) async {
    if (!kDebugMode) return;
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
  }
}

final designPreviewProvider = NotifierProvider<DesignPreviewController, bool>(
  DesignPreviewController.new,
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => ref.watch(designPreviewProvider)
      ? const DesignPreviewLibraryRepository()
      : const PublishedLibraryRepository(),
);

final libraryBooksProvider = FutureProvider<List<Book>>(
  (ref) => ref.watch(libraryRepositoryProvider).books(),
);

final bookProvider = FutureProvider.family<Book?, String>(
  (ref, id) => ref.watch(libraryRepositoryProvider).book(id),
);
