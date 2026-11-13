import 'package:flutter/painting.dart';

/// Home identity (H): green and gold browse surfaces. Values are sampled from
/// reference screenshot 01; see docs/DESIGN_SYSTEM_SPECIFICATION.md §2.1.
abstract final class HomeColors {
  static const bg = Color(0xFFEBEBE9);
  static const surface = Color(0xFFFFFFFF);
  static const green900 = Color(0xFF173D24);
  static const green800 = Color(0xFF1D3D28);
  static const cardGradStart = Color(0xFF396C4B);
  static const cardGradEnd = Color(0xFF234930);
  static const greenChip = Color(0xFF456852);
  static const dhikrTop = Color(0xFF1D3424);
  static const dhikrBottom = Color(0xFF12261A);
  static const gold = Color(0xFFD4A847);
  static const goldLabel = Color(0xFFDEBE6B);
  static const goldRule = Color(0xFFCCAC55);
  static const text = Color(0xFF050B07);
  static const textMuted = Color(0xFF5F615E);
  static const textDate = Color(0xFF575D59);
  static const hamburger = Color(0xFF141915);
  static const sectionRule = Color(0xFFD6D8D4);
  static const tileBorder = Color(0xFFE4E8E4);
  static const tileCool = Color(0xFFFBFDFA);
  static const tileCoolBottom = Color(0xFFF3F9F4);
  static const tileCoolChip = Color(0xFFEAF4EB);
  static const tileCoolChipBorder = Color(0xFFCFE1D2);
  static const tileCoolChipIcon = Color(0xFF2F5A3D);
  static const tileWarm = Color(0xFFFDFAF3);
  static const tileWarmBottom = Color(0xFFFCF5E7);
  static const tileWarmChip = Color(0xFFFBF0DE);
  static const tileWarmChipBorder = Color(0xFFEBD9B8);
  static const tileWarmChipIcon = Color(0xFF6F5520);

  /// White at 80% on the Quran card (DV-02: 4.62:1 instead of about 4.0:1).
  static const onCardMuted = Color(0xCCFFFFFF);
  static const onDark = Color(0xFFF7FFFB);
  static const dhikrDivider = Color(0x40FFFFFF);
}

/// Reader identity (R): teal chrome for reading surfaces, drawer and menus.
/// Sampled from screenshots 02–06; DESIGN_SYSTEM_SPECIFICATION §2.2.
abstract final class ReaderColors {
  static const bar = Color(0xFF20474C);
  static const onBar = Color(0xFFFFFFFF);
  static const icon = Color(0xFF19494D);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1D1D1D);
  static const drawerTitle = Color(0xFF151515);

  /// DV-01: #828284 measured (3.84:1) darkened to pass WCAG AA (4.73:1).
  static const textSecondary = Color(0xFF737375);
  static const divider = Color(0xFFE2E2E2);
  static const handle = Color(0xFFD0D0D0);
  static const pageDark = Color(0xFF000000);
  static const inkDark = Color(0xFFFFFFFF);
  static const ayahMarker = Color(0xFF557560);
  static const highlight = Color(0xFF857460);
  static const drawerActive = Color(0x1419494D);
  static const bannerGrey = Color(0xFF757575);

  /// Provisional light reading palette: the light mode in screenshot 06 is
  /// not shown in any reference (G-09).
  static const pageLight = Color(0xFFFBFAF7);
  static const inkLight = Color(0xFF1A1A1A);
}

/// Proposed semantic colours (DESIGN_SYSTEM_SPECIFICATION §2.3).
abstract final class SemanticColors {
  static const verified = Color(0xFF2E6B47);
  static const draft = Color(0xFF8A6A1F);
  static const error = Color(0xFFA63F3F);
}
