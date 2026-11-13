import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/library/presentation/book_details_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/navigation/domain/app_destination.dart';
import '../features/placeholder/presentation/coming_soon_screen.dart';
import '../features/quran/presentation/quran_index_screen.dart';
import '../features/quran/presentation/quran_reader_screen.dart';
import '../features/settings/presentation/content_sources_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const quran = '/quran';
  static const quranIndex = '/quran/index';
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
        builder: (context, state) => const QuranReaderScreen(),
      ),
      GoRoute(
        path: AppRoutes.quranIndex,
        builder: (context, state) => QuranIndexScreen(
          initialTab: state.uri.queryParameters['tab'] == 'juz' ? 1 : 0,
        ),
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
