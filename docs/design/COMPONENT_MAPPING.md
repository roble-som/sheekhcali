# Component mapping (as built, Phase 1)

How each element of the reference screenshots maps to code.

| Reference element | Screenshot | Widget | File |
|---|---|---|---|
| Hamburger (three lines, short bottom line) | 01 | `HamburgerButton` | `lib/core/widgets/home_components.dart` |
| Weekday, Hijri and Gregorian header | 01 | `DateHeader` + `DateLabels` | `lib/features/home/presentation/widgets/date_header.dart`, `lib/core/calendar/date_labels.dart` |
| Dhikr of the Day card | 01 | `DhikrCard` (placeholders + DV-03 reference line) | `lib/features/home/presentation/widgets/dhikr_card.dart` |
| Quran hero card | 01 | `QuranHeroCard` | `lib/features/home/presentation/widgets/quran_hero_card.dart` |
| Logo medallion | 01, 02 | `LogoMedallion` (placeholder, P-02) | `lib/core/widgets/home_components.dart` |
| Chevron chips | 01 | `ChevronChip` | same |
| EXPLORE label with rule | 01 | `SectionLabel` | same |
| Feature tiles | 01 | `FeatureTile` (cool / warm) | same |
| Navigation drawer | 02 | `AppDrawer` | `lib/features/navigation/presentation/app_drawer.dart` |
| Drawer destinations | 02 | `AppDestination`, `drawerPrimary`, `drawerSecondary` | `lib/features/navigation/domain/app_destination.dart` |
| Reader app bar | 03 | `ReaderAppBar` | `lib/features/quran/presentation/widgets/reader_app_bar.dart` |
| Mushaf page | 03, 04 | `MushafLayoutPreview` (**layout only, no text**) | `lib/features/quran/presentation/widgets/mushaf_layout_preview.dart` |
| Ayah highlight | 04 | highlight inside `MushafLayoutPreview` | same |
| Ayah action sheet | 05 | `showAyahActionSheet` | `lib/features/quran/presentation/widgets/ayah_action_sheet.dart` |
| Overflow menu | 06 | `showReaderOverflowMenu` | `lib/features/quran/presentation/widgets/reader_overflow_menu.dart` |
| Missing asset or content (any) | — | `PlaceholderBox` | `lib/core/widgets/placeholder_box.dart` |

## Icon substitutions

The drawer and reader icons in the references are partly custom. Until icon files are supplied, the closest Material icons stand in:

| Row or action | Reference glyph | Material icon used |
|---|---|---|
| Home | filled house | `Icons.home` |
| Recent Page | page with clock | `Icons.pending_actions` |
| Index & Bookmark | filled bookmark | `Icons.bookmark` |
| My Notes | page with pen | `Icons.edit_document` |
| Itqan | rosette with star | `Icons.workspace_premium_outlined` |
| Statistics | bars with trend arrow | `Icons.leaderboard` (closest; the arrow isn't available) |
| Recitation Correction | the logo | `LogoMedallion` (placeholder) |
| Learn How to Use! | play badge | `Icons.smart_display` |
| Live Chat | chat bubbles | `Icons.forum` |
| Reader: index or book | thin open book, dimmed | `Icons.import_contacts` at 70% white |
| Sheet: Add Note | clipboard with pen | `Icons.note_alt_outlined` |
| Sheet: Copy / Share | document / share-up | `Icons.description_outlined` / `Icons.ios_share` |
| Menu: Go To Page | page with arrow | `Icons.drive_file_move_outline` |

## Added in Phase 1, increment 2

| Element | Source | Widget | File |
|---|---|---|---|
| Toolbar actions with 48 dp targets on a 40 dp pitch | C-18 | `ToolbarActionStrip`, `NearestHitArea` | `lib/core/widgets/toolbar_action_strip.dart` |
| Status chips | Spec §5 `ContentBadge` | `ContentBadge` | `lib/core/widgets/content_badge.dart` |
| Typographic book cover (never an invented image) | Concept 6/7 | `BookCover` | `lib/features/library/presentation/widgets/book_cover.dart` |
| Surah and Juz index with tabs | Concept 5 | `QuranIndexScreen` | `lib/features/quran/presentation/quran_index_screen.dart` |
| Library shelf, list rows, filters, states | Concept 6 | `LibraryScreen`, `BookRow`, `bookBadges` | `lib/features/library/presentation/library_screen.dart` |
| Book details | Concept 7 | `BookDetailsScreen` | `lib/features/library/presentation/book_details_screen.dart` |
| Grouped settings | Concept 16 | `SettingsScreen` | `lib/features/settings/presentation/settings_screen.dart` |
| Content sources and licences | Concept 17 (sources) | `ContentSourcesScreen` | `lib/features/settings/presentation/content_sources_screen.dart` |
| Search folding (interface search only) | Accuracy §3.1 | `foldForSearch` | `lib/core/text/search_folding.dart` |
