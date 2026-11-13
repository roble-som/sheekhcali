/// Spacing, size and shape tokens in logical pixels (dp). Measured values are
/// taken from the reference screenshots at the ASSUMED scale 1 dp = 1.40625 px
/// (a 384 dp wide device, pending P-13). DESIGN_SYSTEM_SPECIFICATION §4.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double gutter = 24;
  static const double cardGap = 14;
  static const double cardPadding = 22;
  static const double tilePadding = 16;
}

abstract final class AppSizes {
  static const double touchMin = 48;
  static const double appBar = 56;
  static const double drawerWidth = 289;
  static const double drawerRow = 48;
  static const double sheetRow = 52;
  static const double menuRow = 48;
  static const double menuWidth = 167;

  static const double dhikrCardHeight = 277;
  static const double quranCardHeight = 106;
  static const double tileMinHeight = 179;
  static const double medallion = 63;
  static const double chevronChip = 28;
  static const double tileChip = 23.5;
  static const double surahHeaderHeight = 43;
}

abstract final class AppRadii {
  static const double card = 16;
  static const double banner = 12;
  static const double sheet = 16;
  static const double menu = 7;
  static const double placeholder = 8;
}
