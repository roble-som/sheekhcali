# Design tokens (as built, Phase 1)

The source of truth is the code. This page maps each token to its origin. Values
were measured from the reference screenshots at the assumed scale 1 dp = 1.40625 px
(P-13), then **calibrated** by overlaying Flutter goldens on the references
(`tool/compare_with_references.py`).

| Area | File |
|---|---|
| Colours | `lib/core/theme/app_colors.dart` (`HomeColors`, `ReaderColors`, `SemanticColors`) |
| Typography | `lib/core/theme/app_typography.dart` (`AppTextStyles`, `AppFonts`) |
| Spacing, sizes, radii | `lib/core/theme/app_spacing.dart` (`AppSpacing`, `AppSizes`, `AppRadii`) |
| Material themes | `lib/core/theme/app_theme.dart` (`AppTheme.home`, `AppTheme.reader`) |

## Colours

The colour tables are in DESIGN_SYSTEM_SPECIFICATION §2. Differences from that specification:

| Token | Value | Why |
|---|---|---|
| `HomeColors.tileCoolBottom` / `tileWarmBottom` | `#F3F9F4` / `#FCF5E7` | The tiles in 01 have a subtle top-to-bottom gradient (sampled near the bottom of each tile) |
| `HomeColors.tile*ChipBorder`, `tile*ChipIcon` | see code | The chevron chips in 01 have a 1 px border and a darker glyph |
| `HomeColors.onCardMuted` | white at 80% | DV-02 (contrast 4.62:1) |
| `ReaderColors.textSecondary` | `#737375` | DV-01 (contrast 4.73:1) |
| `ReaderColors.bannerGrey` | `#757575` | Drawer banner in 02 |
| `kReaderScrim` | black at 60% | Teal `#20474C` dims to about `#0D2024` behind the drawer and sheet (02, 05) |
| `ReaderColors.pageLight` / `inkLight` | `#FBFAF7` / `#1A1A1A` | **Provisional** light reading mode (G-09) |

## Typography (calibrated)

Latin sizes in sp. Arabic uses ×1.12, no letter-spacing and no capitals.

| Style | Size / weight / tracking | Calibration evidence (width in reference px vs Flutter px) |
|---|---|---|
| `weekday` | 12.5 / 600 / 2.1 | THURSDAY 116 vs 119 |
| `hijriDate` | 19.5 / 700 | Hijri line 366 vs 366 |
| `gregorianDate` | 14.5 / 400 | 216 vs 215 |
| `dhikrLabel` | 11.5 / 600 / 2.6 | DHIKR OF THE DAY 206 vs 206 |
| `heroTitle` | 20.5 / 700 | "Quran" 86 vs about 86 |
| `heroSubtitle` | 14.6 / 400, line height 1.25 | wraps after "&", as in the reference |
| `sectionLabel` | 12 / 600 / 2.4 | EXPLORE 92 vs 98 |
| `tileTitle` | 16.5 / 700, line height 1.2 | Khatmah 102 vs 102 |
| `tileSubtitle` | 14.4 / 400, line height 1.4 | three lines, as in the reference |
| `drawerItem` | 14.6 / 400 / 0.4 | rows within 2 px |
| `appBarTitle` | 13.4 / 400 | truncates at about the same point |
| `sheetItem` | 17.2 / 400 | rows within 1 px |
| `menuItem` | 16.5 / 400 | |

## Spacing and geometry (measured)

| Token | Value | Reference |
|---|---|---|
| `AppSpacing.gutter` | 24 | 01 |
| `AppSpacing.cardGap` | 14 | 01 |
| `AppSpacing.cardPadding` | 22 | 01 |
| `AppSizes.dhikrCardHeight` / `quranCardHeight` / `tileMinHeight` | 277 / 106 / 179 | 01 |
| `AppSizes.drawerWidth` / `drawerRow` | 289 / 48 | 02 |
| `AppSizes.appBar` | 56 | 03 |
| `AppSizes.sheetRow` | 52 | 05 |
| `AppSizes.menuWidth` / `menuRow` | 167 (may grow for Arabic) / 48 | 06 |
| Mushaf line pitch | 33.4 | 03 and 04 |
| Mushaf text column | 281 | 03 |
| Surah header | full width − 2 × 13.5, height 43 | 03 |
| `AppRadii.card` / `banner` / `sheet` / `menu` | 16 / 12 / 16 / 7 | 01, 02, 05, 06 |

## Fonts

All bundled; licences are in `assets/fonts/licenses/`. Inter 4.1 (Latin UI, assumed match, G-08), Noto Sans Arabic (Arabic UI), Noto Naskh Arabic (Arabic content). **No Quran font is bundled** (P-24).
