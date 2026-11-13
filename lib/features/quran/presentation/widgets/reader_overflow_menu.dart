import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

enum ReaderMenuAction { search, controls, goToPage, toggleTheme }

/// The teal overflow menu from screenshot 06: 167 dp wide, rows of 48 dp,
/// a 7 dp radius, its top tucked under the app bar and its end edge 16.4 dp
/// from the screen edge.
Future<ReaderMenuAction?> showReaderOverflowMenu(
  BuildContext context, {
  required bool dark,
}) {
  final l10n = AppLocalizations.of(context);
  final styles = context.text;
  final media = MediaQuery.of(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final top = media.padding.top + AppSizes.appBar - 1;
  const endInset = 16.4;
  final width = media.size.width;
  final position = rtl
      ? RelativeRect.fromLTRB(
          endInset,
          top,
          width - endInset - AppSizes.menuWidth,
          0,
        )
      : RelativeRect.fromLTRB(
          width - endInset - AppSizes.menuWidth,
          top,
          endInset,
          0,
        );

  PopupMenuItem<ReaderMenuAction> item(
    ReaderMenuAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<ReaderMenuAction>(
      value: value,
      height: AppSizes.menuRow,
      // PopupMenuItem takes physical insets; resolve start/end ourselves.
      padding: rtl
          ? const EdgeInsets.only(left: 12, right: 8)
          : const EdgeInsets.only(left: 8, right: 12),
      child: Row(
        children: [
          Icon(icon, size: 25, color: ReaderColors.onBar),
          const SizedBox(width: 16.3),
          Expanded(
            child: Text(
              label,
              style: styles.menuItem,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  return showMenu<ReaderMenuAction>(
    context: context,
    position: position,
    color: ReaderColors.bar,
    elevation: 3,
    menuPadding: const EdgeInsets.only(top: 2.6, bottom: 8),
    // 167 dp as measured; longer labels (Arabic) may widen it. The menu stays
    // anchored to the end edge because of how [position] is built above.
    constraints: const BoxConstraints(
      minWidth: AppSizes.menuWidth,
      maxWidth: AppSizes.menuWidth + 90,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.menu),
    ),
    items: [
      item(ReaderMenuAction.search, Icons.search, l10n.menuSearch),
      item(ReaderMenuAction.controls, Icons.tune, l10n.menuControls),
      item(
        ReaderMenuAction.goToPage,
        Icons.drive_file_move_outline,
        l10n.menuGoToPage,
      ),
      item(
        ReaderMenuAction.toggleTheme,
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        dark ? l10n.menuLightMode : l10n.menuDarkMode,
      ),
    ],
  );
}
