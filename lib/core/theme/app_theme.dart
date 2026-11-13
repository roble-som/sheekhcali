import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Material themes for the two identities. Screens use the Home theme by
/// default; reading surfaces wrap themselves in [AppTheme.reader].
abstract final class AppTheme {
  static ThemeData home(Locale locale) {
    final styles = AppTextStyles.forLocale(locale);
    final scheme = ColorScheme.fromSeed(
      seedColor: HomeColors.green900,
      surface: HomeColors.bg,
    ).copyWith(primary: HomeColors.green900, onPrimary: Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: HomeColors.bg,
      fontFamily: styles.family,
      fontFamilyFallback: styles.fallback,
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReaderColors.bar,
        contentTextStyle: styles.body.copyWith(color: Colors.white),
      ),
    );
  }

  static ThemeData reader(ThemeData base, {required bool dark}) {
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? ReaderColors.pageDark
          : ReaderColors.pageLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: ReaderColors.bar,
        foregroundColor: ReaderColors.onBar,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      iconTheme: const IconThemeData(color: ReaderColors.onBar),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ReaderColors.surface,
        showDragHandle: false,
      ),
    );
  }
}
