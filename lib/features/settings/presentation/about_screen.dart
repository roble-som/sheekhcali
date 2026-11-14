import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/app_info.dart';
import '../../../core/build_flags.dart';
import '../../../core/l10n/localized_digits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/home_components.dart';
import '../../../l10n/app_localizations.dart';

/// About Sheekh Calinuur: what this version contains and the state of each
/// part, stated plainly. No claims beyond what the app actually ships.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final locale = Localizations.localeOf(context);

    Widget fact(IconData icon, String title, String body) => ListTile(
      leading: Icon(icon, color: ReaderColors.icon),
      title: Text(title, style: styles.listTitle),
      subtitle: Text(body, style: styles.listSubtitle.copyWith(height: 1.4)),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F4),
        appBar: AppBar(
          backgroundColor: ReaderColors.bar,
          foregroundColor: ReaderColors.onBar,
          title: Text(
            l10n.navAbout,
            style: styles.appBarTitle.copyWith(fontSize: 17),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 28),
            const Center(child: LogoMedallion(size: 112)),
            const SizedBox(height: 16),
            Text(
              l10n.appName,
              textAlign: TextAlign.center,
              style: styles.splashTitle,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.appTagline,
              textAlign: TextAlign.center,
              style: styles.splashTagline,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aboutVersion(localizeDigits(appVersion, locale)),
              key: const ValueKey('about-version'),
              textAlign: TextAlign.center,
              style: styles.listSubtitle,
            ),
            if (kTestingAudioBuild) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  key: const ValueKey('testing-build-banner'),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SemanticColors.draft),
                  ),
                  child: Text(
                    l10n.testingBuildBanner,
                    textAlign: TextAlign.center,
                    style: styles.listSubtitle.copyWith(
                      color: SemanticColors.draft,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Material(
              color: ReaderColors.surface,
              child: Column(
                children: [
                  fact(
                    Icons.auto_stories,
                    l10n.sourceQuranText,
                    l10n.aboutQuranBody,
                  ),
                  fact(
                    Icons.record_voice_over,
                    l10n.aboutTafsirTitle,
                    l10n.aboutTafsirBody,
                  ),
                  fact(
                    Icons.local_library,
                    l10n.navLibrary,
                    l10n.sourceBooksStatus,
                  ),
                  fact(
                    Icons.lock_outline,
                    l10n.aboutPrivacyTitle,
                    l10n.aboutPrivacyBody,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: ReaderColors.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.verified_outlined,
                      color: ReaderColors.icon,
                    ),
                    title: Text(l10n.contentSources, style: styles.listTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.contentSources),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: ReaderColors.icon,
                    ),
                    title: Text(
                      l10n.openSourceLicences,
                      style: styles.listTitle,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appName,
                      applicationVersion: appVersion,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
