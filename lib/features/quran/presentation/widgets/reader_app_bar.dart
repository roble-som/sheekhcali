import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/toolbar_action_strip.dart';
import '../../../../l10n/app_localizations.dart';

/// The teal reader app bar from screenshot 03. All positions are directional,
/// so the bar mirrors in RTL.
class ReaderAppBar extends StatelessWidget {
  const ReaderAppBar({
    super.key,
    required this.title,
    required this.onMenu,
    required this.onBookmark,
    required this.onTranslation,
    required this.onIndex,
    required this.onAutoScroll,
    required this.moreButtonKey,
    required this.onMore,
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onBookmark;
  final VoidCallback onTranslation;
  final VoidCallback onIndex;
  final VoidCallback onAutoScroll;
  final GlobalKey moreButtonKey;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Material(
      color: ReaderColors.bar,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: SizedBox(
          height: AppSizes.appBar,
          // Positions measured from reference 03: the menu icon is centred at
          // 28.4 dp, the title starts at 48.7 dp, and the five actions sit on a
          // 40 dp pitch ending 8.4 dp from the end edge. Every button has a
          // 48 × 48 dp touch target (C-18); see ToolbarActionStrip.
          child: Stack(
            children: [
              PositionedDirectional(
                start: 48.7,
                end: 8.4 + 5 * 40 + 6,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.appBarTitle,
                  ),
                ),
              ),
              PositionedDirectional(
                start: 8.4 - 4,
                top: 0,
                child: ToolbarActionStrip(
                  actions: [
                    ToolbarAction(
                      icon: Icons.menu,
                      tooltip: l10n.openMenu,
                      onPressed: onMenu,
                      iconSize: 23,
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                end: 8.4 - 4,
                top: 0,
                child: ToolbarActionStrip(
                  actions: [
                    ToolbarAction(
                      icon: Icons.bookmark_border,
                      tooltip: l10n.readerBookmark,
                      onPressed: onBookmark,
                    ),
                    ToolbarAction(
                      icon: Icons.language,
                      tooltip: l10n.readerTranslation,
                      onPressed: onTranslation,
                    ),
                    // Drawn dimmed in reference 03, which reads as an "off" toggle.
                    ToolbarAction(
                      icon: Icons.import_contacts,
                      tooltip: l10n.readerIndex,
                      onPressed: onIndex,
                      iconSize: 23,
                      color: const Color(0xB3FFFFFF),
                    ),
                    ToolbarAction(
                      icon: Icons.keyboard_double_arrow_down,
                      tooltip: l10n.readerAutoScroll,
                      onPressed: onAutoScroll,
                      iconSize: 27,
                    ),
                    ToolbarAction(
                      key: moreButtonKey,
                      icon: Icons.more_vert,
                      tooltip: l10n.moreOptions,
                      onPressed: onMore,
                      iconSize: 23,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
