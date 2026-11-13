import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/domain/app_destination.dart';
import '../../navigation/presentation/app_drawer.dart';
import '../../navigation/presentation/drawer_back_scope.dart';
import 'widgets/date_header.dart';
import 'widgets/dhikr_card.dart';
import 'widgets/quran_hero_card.dart';

/// Home dashboard: reference screenshot 01 (DESIGN_SYSTEM_SPECIFICATION §8.2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: HomeColors.bg,
      ),
      child: DrawerBackScope(
        scaffoldKey: _scaffoldKey,
        builder: (context, onDrawerChanged) => Scaffold(
          key: _scaffoldKey,
          onDrawerChanged: onDrawerChanged,
          backgroundColor: HomeColors.bg,
          drawer: const AppDrawer(current: AppDestination.home),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: DateHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 23.9)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  sliver: SliverToBoxAdapter(child: DhikrCard()),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.cardGap),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: QuranHeroCard(
                      // Opens where the user stopped reading (Al-Fatiha
                      // the first time).
                      onTap: () => context.push(AppRoutes.continueReading),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter + 3,
                    15,
                    AppSpacing.gutter,
                    15,
                  ),
                  sliver: SliverToBoxAdapter(child: SectionLabel(l10n.explore)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverToBoxAdapter(child: _FeatureGrid(l10n: l10n)),
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
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    void open(AppDestination d) => context.push(d.path);
    final tiles = [
      FeatureTile(
        title: l10n.khatmahTitle,
        subtitle: l10n.khatmahSubtitle,
        tone: FeatureTileTone.cool,
        onTap: () => open(AppDestination.khatmah),
      ),
      FeatureTile(
        title: l10n.prayerTitle,
        subtitle: l10n.prayerSubtitle,
        tone: FeatureTileTone.warm,
        onTap: () => open(AppDestination.prayerTimes),
      ),
      // Approved additions (DESIGN_SYSTEM_SPECIFICATION §7): new features join
      // the existing grid in the same style. Order pending G-13.
      FeatureTile(
        title: l10n.libraryTitle,
        subtitle: l10n.librarySubtitle,
        tone: FeatureTileTone.warm,
        onTap: () => open(AppDestination.library),
      ),
      FeatureTile(
        title: l10n.lessonsTitle,
        subtitle: l10n.lessonsSubtitle,
        tone: FeatureTileTone.cool,
        onTap: () => open(AppDestination.lessons),
      ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: AppSpacing.cardGap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: AppSpacing.cardGap),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
