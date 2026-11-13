import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/app_destination.dart';

/// Scrim behind the open drawer and sheets, measured from screenshots 02 and 05
/// (teal #20474C dims to about #0D2024).
const kReaderScrim = Color(0x99000000);

/// Navigation drawer (screenshot 02, DESIGN_SYSTEM_SPECIFICATION §8.3).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.current});

  /// The destination currently shown, if it's a drawer row (gets the active tint).
  final AppDestination? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final topInset = MediaQuery.paddingOf(context).top;

    void open(AppDestination d) {
      Navigator.of(context).pop();
      if (d == current) return;
      if (d == AppDestination.home) {
        context.go(d.path);
      } else {
        context.push(d.path);
      }
    }

    Widget row(AppDestination d) => _DrawerRow(
      destination: d,
      label: d.label(l10n),
      active: d == current,
      onTap: () => open(d),
    );

    return Drawer(
      width: AppSizes.drawerWidth,
      backgroundColor: ReaderColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: ListView(
        padding: EdgeInsets.only(top: topInset, bottom: 16),
        children: [
          SizedBox(
            height: 77.5,
            child: Row(
              children: [
                const SizedBox(width: 16.7),
                const LogoMedallion(size: 43),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.appName,
                    style: styles.drawerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: ReaderColors.divider),
          const SizedBox(height: 1.2),
          for (final d in drawerPrimary) row(d),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 7.3, 17, 8),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: ReaderColors.bannerGrey,
                borderRadius: BorderRadius.circular(AppRadii.banner),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const LogoMedallion(size: 96, onDark: true),
                  PositionedDirectional(
                    bottom: 6,
                    start: 8,
                    end: 8,
                    child: Text(
                      l10n.drawerBannerPlaceholder,
                      textAlign: TextAlign.center,
                      style: styles.placeholderLabel.copyWith(
                        color: const Color(0xD9FFFFFF),
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          row(drawerSecondary.first),
          const SizedBox(height: 24),
          for (final d in drawerSecondary.skip(1)) row(d),
        ],
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.destination,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final AppDestination destination;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = destination.icon;
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? ReaderColors.drawerActive : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.drawerRow,
            child: Row(
              children: [
                SizedBox(
                  width: 59.7,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4.6),
                      child: icon == null
                          ? const LogoMedallion(size: 26)
                          : Icon(icon, size: 24, color: ReaderColors.icon),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.drawerItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
