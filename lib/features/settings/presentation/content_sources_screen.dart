import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// What content and resources the app contains, and their status. It states
/// plainly that no Quran text or books are installed yet.
class ContentSourcesScreen extends StatelessWidget {
  const ContentSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;

    Widget row(
      IconData icon,
      String title,
      String status, {
      bool pending = false,
    }) => ListTile(
      leading: Icon(icon, color: ReaderColors.icon),
      title: Text(title, style: styles.listTitle),
      subtitle: Text(
        status,
        style: styles.listSubtitle.copyWith(
          color: pending ? SemanticColors.draft : ReaderColors.textSecondary,
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F4),
        appBar: AppBar(
          backgroundColor: ReaderColors.bar,
          foregroundColor: ReaderColors.onBar,
          title: Text(
            l10n.contentSources,
            style: styles.appBarTitle.copyWith(fontSize: 17),
          ),
        ),
        body: ListView(
          children: [
            Material(
              color: ReaderColors.surface,
              child: Column(
                children: [
                  row(
                    Icons.auto_stories,
                    l10n.sourceQuranText,
                    l10n.sourceQuranTextFatiha,
                    pending: true,
                  ),
                  row(
                    Icons.format_list_numbered,
                    l10n.sourceQuranMetadata,
                    l10n.sourceNotInstalled,
                    pending: true,
                  ),
                  row(
                    Icons.translate,
                    l10n.sourceTranslation,
                    l10n.sourceNotInstalled,
                    pending: true,
                  ),
                  row(
                    Icons.local_library,
                    l10n.sourceBooks,
                    l10n.sourceBooksStatus,
                    pending: true,
                  ),
                  row(
                    Icons.calendar_month,
                    l10n.sourceHijri,
                    l10n.sourceHijriStatus,
                  ),
                  row(
                    Icons.font_download_outlined,
                    l10n.sourceFonts,
                    l10n.sourceFontsStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.openLicences),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
