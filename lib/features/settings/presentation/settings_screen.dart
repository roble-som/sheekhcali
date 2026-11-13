import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/calendar/date_labels.dart';
import '../../../core/l10n/localized_digits.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../library/data/library_repository.dart';
import '../../navigation/domain/app_destination.dart';
import '../application/preferences_controllers.dart';
import '../../quran/presentation/widgets/reading_controls.dart';

/// Settings (concept 16, DESIGN_SYSTEM_SPECIFICATION §8.16): Reader chrome and
/// a grouped white list. Only settings that work, or are clearly marked as
/// taking effect later, are shown.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final locale = Localizations.localeOf(context);
    final chosen = ref.watch(localeControllerProvider);
    final dark = ref.watch(readerDarkProvider);
    final adjustment = ref.watch(hijriAdjustmentProvider);
    final wifiOnly = ref.watch(wifiOnlyProvider);
    final preview = ref.watch(designPreviewProvider);
    final today = DateLabels.build(
      now: ref.watch(clockProvider)(),
      locale: locale,
      l10n: l10n,
      converter: ref.watch(hijriConverterProvider),
    ).hijri;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F4),
        appBar: AppBar(
          backgroundColor: ReaderColors.bar,
          foregroundColor: ReaderColors.onBar,
          title: Text(
            l10n.navSettings,
            style: styles.appBarTitle.copyWith(fontSize: 17),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Header(l10n.settingsSectionGeneral),
            _Group(
              children: [
                _GroupTitle(
                  icon: Icons.translate,
                  title: l10n.settingsLanguage,
                ),
                RadioGroup<String>(
                  groupValue: chosen?.languageCode ?? 'system',
                  onChanged: (v) => ref
                      .read(localeControllerProvider.notifier)
                      .select(v == null || v == 'system' ? null : Locale(v)),
                  child: Column(
                    children: [
                      _Radio(value: 'system', label: l10n.languageSystem),
                      _Radio(value: 'en', label: l10n.languageEnglish),
                      _Radio(
                        value: 'ar',
                        label: l10n.languageArabic,
                        fontFamily: AppFonts.arabicUi,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Header(l10n.settingsReaderTheme),
            _Group(
              children: [
                RadioGroup<bool>(
                  groupValue: dark,
                  onChanged: (v) => ref
                      .read(readerDarkProvider.notifier)
                      .set(dark: v ?? true),
                  child: Column(
                    children: [
                      _Radio<bool>(value: true, label: l10n.readerThemeDark),
                      _Radio<bool>(value: false, label: l10n.readerThemeLight),
                    ],
                  ),
                ),
                Padding(
                  // Aligned with the radio rows above (start 56 + 16).
                  padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 8, 4),
                  child: QuranTextSizeControl(
                    dark: false,
                    textStyle: styles.listTitle,
                  ),
                ),
              ],
            ),
            _Header(l10n.settingsSectionHijri),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.calendar_month,
                    color: ReaderColors.icon,
                  ),
                  title: Text(l10n.hijriMethod, style: styles.listTitle),
                  subtitle: Text(
                    l10n.hijriMethodUmmAlQura,
                    style: styles.listSubtitle,
                  ),
                ),
                const Divider(height: 1, indent: 56),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: ReaderColors.icon),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.hijriAdjustment,
                              style: styles.listTitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 40),
                        child: Text(
                          l10n.hijriAdjustmentHint,
                          style: styles.listSubtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: [
                            for (final d in const [-2, -1, 0, 1, 2])
                              ButtonSegment<int>(
                                value: d,
                                tooltip: l10n.hijriAdjustmentSemantics(
                                  localizeDigits(_signed(d), locale),
                                ),
                                label: Text(
                                  localizeDigits(_signed(d), locale),
                                  // Keep the sign before the number in RTL.
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                          ],
                          selected: {adjustment},
                          onSelectionChanged: (s) => ref
                              .read(hijriAdjustmentProvider.notifier)
                              .set(s.first),
                        ),
                      ),
                      if (today != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.hijriToday(today),
                          style: styles.listSubtitle.copyWith(
                            color: HomeColors.green900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _Header(l10n.settingsSectionDownloads),
            _Group(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wifi, color: ReaderColors.icon),
                  title: Text(l10n.wifiOnly, style: styles.listTitle),
                  subtitle: Text(l10n.wifiOnlyHint, style: styles.listSubtitle),
                  value: wifiOnly,
                  onChanged: (v) =>
                      ref.read(wifiOnlyProvider.notifier).set(value: v),
                ),
              ],
            ),
            _Header(l10n.settingsSectionAbout),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.source_outlined,
                    color: ReaderColors.icon,
                  ),
                  title: Text(l10n.contentSources, style: styles.listTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.contentSources),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: ReaderColors.icon,
                  ),
                  title: Text(l10n.aboutApp, style: styles.listTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppDestination.about.path),
                ),
              ],
            ),
            if (kDebugMode) ...[
              _Header(l10n.settingsSectionDeveloper),
              _Group(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFF6A4E12),
                    ),
                    title: Text(l10n.designPreview, style: styles.listTitle),
                    subtitle: Text(
                      l10n.designPreviewHint,
                      style: styles.listSubtitle,
                    ),
                    value: preview,
                    onChanged: (v) => ref
                        .read(designPreviewProvider.notifier)
                        .set(enabled: v),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _signed(int d) => d > 0 ? '+$d' : (d < 0 ? '−${-d}' : '0');
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 6),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: context.text.listSubtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// White group surface. A Material, so list tiles keep their ink.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReaderColors.surface,
      child: Column(children: children),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ReaderColors.icon),
      title: Text(title, style: context.text.listTitle),
    );
  }
}

class _Radio<T> extends StatelessWidget {
  const _Radio({required this.value, required this.label, this.fontFamily});

  final T value;
  final String label;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 16),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        label,
        style: context.text.listTitle.copyWith(fontFamily: fontFamily),
      ),
    );
  }
}
