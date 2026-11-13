# Design reference inventory

Phase 0 snapshot, 2026-11-13 (revised the same day). The six owner-supplied screenshots below are the design specification (master prompt §4). They are stored in `docs/design/reference/`. The owner's later copies in `images/` (WhatsApp filenames) are byte-identical (SHA-256 checked 2026-11-13).

## About the measurements

- Every screenshot is a **540 × 1170 px JPEG**, scaled down from a phone capture of an Android device with a three-button navigation bar and One UI-style status icons.
- **Scale (ASSUMED):** the layout fits a logical width of about 384 dp, which gives **1 dp ≈ 1.406 px** in these images. On that basis the page gutter is 34 px ≈ 24 dp and drawer rows are 67.5 px ≈ 48 dp, both standard Material values. The phone model or a full-resolution capture would confirm it.
- **Colours** were sampled from the JPEGs. Compression shifts them by a few units, so treat them as ±3 per channel. Gradients are sampled at their ends.
- Positions are given in image px as `x1–x2, y1–y2`.

## Screen inventory

| # | File | Screen | Mode | Branding shown |
|---|---|---|---|---|
| 01 | `01-home.jpg` | Home dashboard (top part; the page scrolls further) | Light | None |
| 02 | `02-drawer.jpg` | Navigation drawer, open over the Quran reader | Light drawer over a dark reader | "Quran Tabsera" + logo |
| 03 | `03-mushaf-reader.jpg` | Quran reader, mushaf page mode, Al-Fatiha | Dark | Hijri date in the app bar |
| 04 | `04-mushaf-ayah-selected.jpg` | Same page with ayah 6 selected | Dark | |
| 05 | `05-ayah-action-sheet.jpg` | Ayah action bottom sheet | Light sheet over a dark reader | |
| 06 | `06-reader-overflow-menu.jpg` | Reader overflow menu, Al-Baqarah page | Dark | |

## 01 Home

Component tree, from top to bottom:

1. **Header** (no app bar background; it sits on the page background `#EBEBE9`)
   - Hamburger icon, left, `40–72, 85–110`, colour about `#141915`.
   - Centred block:
     - Gold dot `#D4A847` + weekday "THURSDAY": uppercase, letter-spaced, semibold, dark green `#1D3D28`, about 12 sp.
     - Hijri date "2 Jumada al-Thani 1448 AH": bold, dark green `#173D24`, about 19–20 sp.
     - Gregorian date "12 November 2026 CE": regular, grey `#575D59`, about 12–13 sp.
2. **Dhikr of the Day card**, `34–506, 203–592`, radius about 16 dp, soft shadow.
   - Background: a photo of a mosque silhouette under a dark green overlay (`#12261A` to `#1D3424`). **The photo is an image asset I don't have.**
   - Label row: gold rule `#CCAC55` (about 26 dp wide) + "DHIKR OF THE DAY" in gold `#DEBE6B`, uppercase, letter-spaced, semibold.
   - Arabic dhikr: white, centred, Naskh, about 20 sp, wraps to two lines. **The card shows no source reference for the dhikr.** The accuracy rules need one (P-12, DV-03).
   - Thin divider in low-opacity white.
   - English translation: white `#F7FFFB`, **justified**, about 15 sp, line height about 1.6.
3. **Quran card**, `34–506, 612–761`, radius about 16 dp.
   - Gradient from `#396C4B` (left) to `#234930` (right).
   - Round logo medallion, gold ring, about 64 dp, left.
   - "Quran" in white, bold, about 20 sp; "Read, Listen, Tafsir & Explore" in white at reduced opacity, about 14 sp.
   - Chevron in a circle `#456852`, about 28 dp, right.
4. **Section label** "EXPLORE": grey `#5D5F5C`, uppercase, letter-spaced about 2 dp, semibold, with a hairline rule running to the right edge.
5. **Feature tile grid**: two columns, gap about 14 dp, tiles `34–260` and `280–505`, radius about 16 dp, 1 px light border, faint shadow.
   - Khatmah tile: background `#FBFDFA`, chevron chip `#EAF4EB`, illustration (Quran stand with a check rosette).
   - Prayer Times & Qibla tile: background `#FDFAF3` (warm), chevron chip `#FBF0DE`, illustration (clock and Kaaba).
   - Title: near-black `#050B07`, bold, about 18 sp. Subtitle: grey `#5F615E`, about 14 sp, joined with " · ".
   - **More tiles exist below the fold** (the tops of two more are visible at y ≈ 1100). Not shown.
6. Android system navigation bar (system UI, not part of the app).

## 02 Navigation drawer

- Width about 75% of the screen (406 / 540 px), white `#FFFFFF`; the reader behind it is dimmed.
- Header: round logo about 43 dp + "Quran Tabsera" in `#151515`, about 18 sp, medium weight. A divider `#E2E2E2` follows.
- Rows, 48 dp apart, icon colour `#19494D` (dark teal), label `#1D1D1D` about 16 sp:
  Home · Recent Page · Index & Bookmark · My Notes · Itqan · Statistics · Recitation Correction (logo icon).
- A grey `#757575` banner, radius about 12 dp, with the logo centred. Its purpose is unclear: a placeholder or a promotional image.
- Rows: Learn How to Use! · (gap) · Settings · About · Live Chat (cut off; the list scrolls).
- **There are no rows yet for the library, books, lessons, Tafsir or downloads.** See DESIGN_GAPS.

## 03 Quran reader, mushaf page mode

- App bar `#20474C` (dark teal), white icons: menu, truncated Hijri date "02 Jumada al-Thani…", bookmark, globe (translation?), open book (Tafsir or index?), double chevron down (auto-scroll?), overflow.
- Page background `#000000` in dark mode.
- Surah header: an ornamental frame (rust `#BA5028` with green and gold arabesque) with the surah name in the centre. **An image asset I don't have.**
- Mushaf text: white, Madinah-mushaf script with page-accurate line breaks; ayah-number rosettes in green `#557560`.
- The page is vertically centred, with large empty areas above and below (the Fatiha page is short).

## 04 Ayah selected

- The selected ayah's span gets a rectangular highlight about `#857460` (muted brown-gold), covering each line segment of the ayah. It is applied on a long press or tap; the gesture isn't shown.

## 05 Ayah action sheet

- A white modal bottom sheet with a top corner radius of about 16 dp and a drag handle.
- Rows with a black icon and a two-tone label (primary black, secondary grey `#828284`):
  Play *to the end of sura* · Play *Tafsir* · Play *Recitation + Tafsir* · Add Note · Add Itqan · Tafsir · Bookmark · (divider) · Copy · Share.

## 06 Reader overflow menu

- A popup menu in `#20474C` with white icons and text: Search · Controls · Go To Page · Light mode.
- This shows that the reader has a light mode as well. **It isn't shown.**

## Colour summary (sampled)

| Token (proposed name) | Value | Seen in |
|---|---|---|
| `bgPage` | `#EBEBE9` | Home background |
| `greenDeep` | `#173D24` | Hijri date, headings |
| `greenCardStart` / `greenCardEnd` | `#396C4B` / `#234930` | Quran card gradient |
| `greenChip` | `#456852` | Quran card chevron |
| `dhikrOverlay` | `#12261A`–`#1D3424` | Dhikr card |
| `gold` | `#D4A847` | Weekday dot |
| `goldLabel` / `goldRule` | `#DEBE6B` / `#CCAC55` | Dhikr label and rule |
| `textPrimary` | `#050B07` | Tile titles |
| `textSecondary` | `#5F615E` / `#575D59` | Subtitles, Gregorian date |
| `tileGreenBg` / `tileGreenChip` | `#FBFDFA` / `#EAF4EB` | Khatmah tile |
| `tileWarmBg` / `tileWarmChip` | `#FDFAF3` / `#FBF0DE` | Prayer tile |
| `tealBar` | `#20474C` | Reader app bar, overflow menu |
| `tealIcon` | `#19494D` | Drawer icons |
| `readerBgDark` | `#000000` | Mushaf, dark mode |
| `ayahMarker` | `#557560` | Ayah rosettes |
| `ayahHighlight` | `#857460` | Selected ayah |
| `divider` | `#E2E2E2` | Drawer |

**Two visual identities: kept by decision C-05.** The Home screen uses green, gold and soft cards. The reader and drawer use teal `#20474C` with plain Material surfaces. Both are kept. DESIGN_SYSTEM_SPECIFICATION §2 names them `h.*` and `r.*`.

## Measured dimensions (edge detection on the 540 px images, 2026-11-13)

| Element | Image px | ≈ dp (at 1.406 px/dp, ASSUMED) |
|---|---|---|
| Page gutter | 34 | 24 |
| Dhikr card | x 34–506, y ≈ 203–592 | 336 × 277 |
| Quran card | x 34–506, y ≈ 612–761 | 336 × 106 |
| Gap between the hero cards | ≈ 20 | 14 |
| Quran medallion | x 67–152 | 60 |
| Feature tiles | x 35–260 and 280–505, y 826–≈1078 | 160 × 179, gap 14 |
| Reader app bar (below the status bar) | bottom edge at y ≈ 129 | ≈ 56 |
| Surah header frame | x 19–522, y ≈ 371–431 | 358 wide; side margin ≈ 13.5 |
| Drawer width | 406 | ≈ 289 (Material default 304; see P-13) |
| Drawer row pitch | 67.5 | 48 |
| Drawer banner | x ≈ 23–383, y 644–812 | ≈ 256 × 120, radius ≈ 12 |
| Bottom-sheet top edge (05) | y ≈ 410 | — |

## Contrast of the measured pairs (WCAG formula)

Full table in DESIGN_SYSTEM_SPECIFICATION §10. Two pairs fail AA for normal text: sheet secondary text `#828284` on white (**3.84:1**), and the Quran card subtitle at about 70% white on `#396C4B` (**about 4.0:1**). Proposed fixes are DV-01 and DV-02.

## Typography (estimated)

- The Latin UI looks like **Inter** or a close geometric sans (the single-storey "a" and the shape of the digits suggest Inter). NOT VERIFIED; the font file or its name is needed.
- Arabic UI and dhikr text: a Naskh face (could be Noto Naskh Arabic or Amiri; NOT VERIFIED).
- Mushaf: a KFGQPC Uthmanic page font or pre-rendered page images. See G-04.

## Assets visible but not supplied

| Asset | Used in | Status |
|---|---|---|
| Logo (gold-ringed medallion with green calligraphy) | 01, 02 | NOT FOUND as a file |
| Mosque photo for the dhikr background | 01 | NOT FOUND |
| Khatmah illustration | 01 | NOT FOUND |
| Prayer & Qibla illustration | 01 | NOT FOUND |
| Surah header frame | 03, 06 | NOT FOUND |
| Ayah number rosette | 03–06 | NOT FOUND (it may come from the mushaf font) |
| Drawer icons (custom: Recent Page, Itqan, Recitation Correction) | 02 | NOT FOUND. Most rows can use close Material Symbols |
