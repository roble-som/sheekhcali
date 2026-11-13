import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Every place the drawer or Home can open. Destinations that aren't built yet
/// route to the "coming in a later phase" screen, never to invented content.
enum AppDestination {
  home('/', Icons.home),
  library('/library', Icons.local_library),
  lessons('/soon/lessons', Icons.headphones),
  tafsir('/soon/tafsir', Icons.menu_book),
  downloads('/soon/downloads', Icons.download_for_offline),
  recentPage('/soon/recent-page', Icons.pending_actions),
  indexBookmark('/quran/index', Icons.bookmark),
  myNotes('/soon/my-notes', Icons.edit_document),
  itqan('/soon/itqan', Icons.workspace_premium_outlined),
  statistics('/soon/statistics', Icons.leaderboard),
  recitationCorrection('/soon/recitation-correction', null),
  learnHowToUse('/soon/learn-how-to-use', Icons.smart_display),
  settings('/settings', Icons.settings),
  about('/soon/about', Icons.info),
  liveChat('/soon/live-chat', Icons.forum),
  quran('/quran', Icons.auto_stories),
  khatmah('/soon/khatmah', Icons.auto_stories),
  prayerTimes('/soon/prayer-times', Icons.schedule);

  const AppDestination(this.path, this.icon);

  final String path;

  /// Null means the reference uses the logo medallion as the icon.
  final IconData? icon;

  /// Whether this destination is one of the proposed drawer rows (DV-05).
  bool get isProposedAddition => const {
    AppDestination.library,
    AppDestination.lessons,
    AppDestination.tafsir,
    AppDestination.downloads,
  }.contains(this);

  String label(AppLocalizations l10n) => switch (this) {
    AppDestination.home => l10n.navHome,
    AppDestination.library => l10n.navLibrary,
    AppDestination.lessons => l10n.navLessons,
    AppDestination.tafsir => l10n.navTafsir,
    AppDestination.downloads => l10n.navDownloads,
    AppDestination.recentPage => l10n.navRecentPage,
    AppDestination.indexBookmark => l10n.navIndexBookmark,
    AppDestination.myNotes => l10n.navMyNotes,
    AppDestination.itqan => l10n.navItqan,
    AppDestination.statistics => l10n.navStatistics,
    AppDestination.recitationCorrection => l10n.navRecitationCorrection,
    AppDestination.learnHowToUse => l10n.navLearnHowToUse,
    AppDestination.settings => l10n.navSettings,
    AppDestination.about => l10n.navAbout,
    AppDestination.liveChat => l10n.navLiveChat,
    AppDestination.quran => l10n.quranCardTitle,
    AppDestination.khatmah => l10n.khatmahTitle,
    AppDestination.prayerTimes => l10n.prayerTitle,
  };

  static AppDestination? fromSoonSlug(String slug) {
    for (final d in values) {
      if (d.path == '/soon/$slug') return d;
    }
    return null;
  }
}

/// Drawer layout: primary rows, then the banner, then secondary rows
/// (screenshot 02 plus the approved DV-05 additions).
const drawerPrimary = [
  AppDestination.home,
  AppDestination.library,
  AppDestination.lessons,
  AppDestination.tafsir,
  AppDestination.downloads,
  AppDestination.recentPage,
  AppDestination.indexBookmark,
  AppDestination.myNotes,
  AppDestination.itqan,
  AppDestination.statistics,
  AppDestination.recitationCorrection,
];

const drawerSecondary = [
  AppDestination.learnHowToUse,
  AppDestination.settings,
  AppDestination.about,
  AppDestination.liveChat,
];
