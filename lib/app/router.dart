import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/library/presentation/book_details_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/navigation/domain/app_destination.dart';
import '../features/placeholder/presentation/coming_soon_screen.dart';
import '../features/quran/application/reading_state.dart';
import '../features/quran/presentation/quran_index_screen.dart';
import '../features/quran/presentation/quran_search_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/quran/presentation/quran_reader_screen.dart';
import '../features/settings/presentation/content_sources_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const quran = '/quran';
  static const quranIndex = '/quran/index';
  static const quranSearch = '/quran/search';
  static const continueReading = '/quran/continue';
  static const about = '/about';

  /// The reader at [surah], scrolled to [ayah] if given.
  static String quranAt(int surah, [int? ayah]) =>
      '/quran?surah=$surah${ayah == null ? '' : '&ayah=$ayah'}';

  /// The reader at Madinah Mushaf page [page].
  static String quranPage(int page) => '/quran?page=$page';

  /// The index opened on a tab: 'surah', 'juz' or 'bookmarks'.
  static String quranIndexTab(String tab) => '/quran/index?tab=$tab';
  static const library = '/library';
  static const contentSources = '/settings/sources';
  static String book(String id) => '/library/book/$id';
  static const settings = '/settings';
}

/// The initial location. Tests override it to open a screen directly.
final initialLocationProvider = Provider<String>((ref) => AppRoutes.splash);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.quran,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final surah = (int.tryParse(q['surah'] ?? '') ?? 1).clamp(1, 114);
          final ayah = int.tryParse(q['ayah'] ?? '');
          final page = int.tryParse(q['page'] ?? '');
          return QuranReaderScreen(
            key: ValueKey('reader-$surah-$ayah-$page'),
            surah: surah,
            initialAyah: ayah,
            page: page,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quranIndex,
        builder: (context, state) => QuranIndexScreen(
          initialTab: switch (state.uri.queryParameters['tab']) {
            'juz' => 1,
            'bookmarks' => 2,
            _ => 0,
          },
        ),
      ),
      // "Continue reading": the last place read, or Al-Fatiha.
      GoRoute(
        path: AppRoutes.continueReading,
        redirect: (context, state) {
          final last = ref.read(lastReadProvider);
          return AppRoutes.quranAt(last?.surah ?? 1, last?.ayah);
        },
      ),
      GoRoute(
        path: AppRoutes.quranSearch,
        builder: (context, state) => const QuranSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/library/book/:id',
        builder: (context, state) =>
            BookDetailsScreen(bookId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.contentSources,
        builder: (context, state) => const ContentSourcesScreen(),
      ),
      GoRoute(
        path: '/soon/:slug',
        builder: (context, state) => ComingSoonScreen(
          destination: AppDestination.fromSoonSlug(
            state.pathParameters['slug'] ?? '',
          ),
        ),
      ),
    ],
  );
});
