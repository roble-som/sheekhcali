import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Font families bundled with the app (assets/fonts, SIL OFL 1.1).
abstract final class AppFonts {
  /// Latin UI. Inter is the assumed match for the references (G-08).
  static const latin = 'Inter';

  /// Arabic UI (G-11, proposed).
  static const arabicUi = 'NotoSansArabic';

  /// Arabic content text such as dhikr, Tafsir and book text (not Quran).
  static const arabicContent = 'NotoNaskhArabic';

  /// Quran text only (Tanzil Uthmani), Amiri under SIL OFL 1.1.
  static const quran = 'AmiriQuranText';
}

/// Text styles for one script. Use [AppTextStyles.of] to get the set that
/// matches the active locale.
///
/// Sizes are measured from the reference screenshots (cap heights at the assumed
/// scale). Arabic sizes are about 12% larger so they look the same size as Latin,
/// and Arabic never uses letter-spacing, which breaks the joins between letters
/// (DESIGN_SYSTEM_SPECIFICATION §3.2).
@immutable
class AppTextStyles {
  const AppTextStyles._(this.isArabic);

  final bool isArabic;

  static const _latin = AppTextStyles._(false);
  static const _arabic = AppTextStyles._(true);

  static AppTextStyles of(BuildContext context) =>
      forLocale(Localizations.localeOf(context));

  static AppTextStyles forLocale(Locale locale) =>
      locale.languageCode == 'ar' ? _arabic : _latin;

  String get family => isArabic ? AppFonts.arabicUi : AppFonts.latin;

  List<String> get fallback =>
      isArabic ? const [AppFonts.latin] : const [AppFonts.arabicUi];

  TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = 0,
    double? arabicHeight,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: isArabic ? (size * 1.12) : size,
      fontWeight: weight,
      color: color,
      height: isArabic ? (arabicHeight ?? height) : height,
      letterSpacing: isArabic ? 0 : letterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  // Home header (screenshot 01).
  TextStyle get weekday => _style(
    12.5,
    weight: FontWeight.w600,
    color: HomeColors.green800,
    letterSpacing: 2.1,
  );
  TextStyle get hijriDate => _style(
    19.5,
    weight: FontWeight.w700,
    color: HomeColors.green900,
    height: 1.2,
    arabicHeight: 1.35,
  );
  TextStyle get gregorianDate =>
      _style(14.5, color: HomeColors.textDate, height: 1.2, arabicHeight: 1.4);

  // Dhikr card.
  TextStyle get dhikrLabel => _style(
    11.5,
    weight: FontWeight.w600,
    color: HomeColors.goldLabel,
    letterSpacing: 2.6,
  );
  TextStyle get dhikrTranslation =>
      _style(15, color: HomeColors.onDark, height: 1.66, arabicHeight: 1.8);

  // Quran hero card.
  TextStyle get heroTitle => _style(
    20.5,
    weight: FontWeight.w700,
    color: HomeColors.onDark,
    height: 1.15,
    arabicHeight: 1.35,
  );
  TextStyle get heroSubtitle => _style(
    14.6,
    color: HomeColors.onCardMuted,
    height: 1.25,
    arabicHeight: 1.5,
  );

  // Section label and feature tiles.
  TextStyle get sectionLabel => _style(
    12,
    weight: FontWeight.w600,
    color: HomeColors.textMuted,
    letterSpacing: 2.4,
  );
  TextStyle get tileTitle => _style(
    16.5,
    weight: FontWeight.w700,
    color: HomeColors.text,
    height: 1.2,
    arabicHeight: 1.4,
  );
  TextStyle get tileSubtitle => _style(
    14.4,
    color: HomeColors.textMuted,
    height: 1.4,
    arabicHeight: 1.55,
  );

  // Splash.
  TextStyle get splashTitle => _style(
    26,
    weight: FontWeight.w700,
    color: HomeColors.green900,
    height: 1.2,
  );
  TextStyle get splashTagline =>
      _style(14, color: HomeColors.textMuted, height: 1.3);

  // Reader identity.
  TextStyle get drawerTitle =>
      _style(18.5, weight: FontWeight.w500, color: ReaderColors.drawerTitle);
  TextStyle get drawerItem =>
      _style(14.6, color: ReaderColors.text, letterSpacing: 0.4);
  TextStyle get appBarTitle => _style(13.4, color: ReaderColors.onBar);
  TextStyle get sheetItem => _style(17.2, color: ReaderColors.text);
  TextStyle get sheetItemSecondary =>
      _style(17.2, color: ReaderColors.textSecondary);
  TextStyle get menuItem => _style(16.5, color: ReaderColors.onBar);
  TextStyle get noticeTitle =>
      _style(13, weight: FontWeight.w600, color: ReaderColors.onBar);
  TextStyle get noticeBody => _style(
    12.5,
    color: const Color(0xD9FFFFFF),
    height: 1.4,
    arabicHeight: 1.6,
  );

  // General.
  TextStyle get title => _style(
    20,
    weight: FontWeight.w700,
    color: HomeColors.green900,
    height: 1.25,
    arabicHeight: 1.45,
  );
  TextStyle get body =>
      _style(15, color: HomeColors.text, height: 1.5, arabicHeight: 1.7);
  TextStyle get listTitle => _style(15.5, color: ReaderColors.text);
  TextStyle get listSubtitle => _style(13, color: ReaderColors.textSecondary);
  TextStyle get placeholderLabel =>
      _style(11, weight: FontWeight.w500, height: 1.3, arabicHeight: 1.5);
}

extension AppTextStylesContext on BuildContext {
  AppTextStyles get text => AppTextStyles.of(this);
}
