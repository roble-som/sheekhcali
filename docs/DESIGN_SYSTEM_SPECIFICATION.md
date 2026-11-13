# Design system specification

Phase 0, 2026-11-13. **Status: Proposed direction, awaiting owner approval.** Measured values come from the six reference screenshots (`docs/design/DESIGN_REFERENCE_INVENTORY.md`). Anything not measurable from them is marked **Proposed**. The visual concepts are in `docs/design/concepts/` and are labelled as concepts, not approved designs.

Measurement scale is **ASSUMED**: 1 dp ≈ 1.406 px in the 540 px-wide screenshots (a device about 384 dp wide). Every dp value below inherits this assumption until a full-resolution capture or the phone model confirms it (decision P-13).

---

## 1. Design principles

1. **The text comes first.** Quran, Tafsir and book text get the largest type, the calmest surfaces and the fewest distractions. Interface chrome stays out of the way while reading.
2. **Trust is visible.** Every piece of religious content shows what it is (Quran, Tafsir, the Sheikh's explanation, translation, editorial note), where it came from, and whether it is verified. Labels are quiet but always there.
3. **Two identities with one rule.** *Browse* surfaces use the Home identity (green and gold). *Reading and listening* surfaces use the Reader identity (teal chrome). Both come from the references and both are kept (spec §5).
4. **Calm, not decorative.** No ornament except where the references have it (the surah frame, the medallion, the dhikr photo). No gradients beyond the one on the Quran card. Motion only explains a change of state.
5. **Bilingual by construction.** Every layout is written with start and end, never left and right. Arabic is designed for, not mirrored after the fact.
6. **Honest states.** Offline, not downloaded, unverified, missing rights and empty are each designed as states, never as error popups.
7. **Measure, don't guess.** Reference values are kept as measured. Any deviation (for example for contrast) is recorded in §11 with its reason.

---

## 2. Colour system

### 2.1 Identity H: Home and browse (screenshot 01)

| Token | Value | Role |
|---|---|---|
| `h.bg` | `#EBEBE9` | Page background |
| `h.surface` | `#FFFFFF` | Plain cards and sheets (Proposed for screens without a reference) |
| `h.green900` | `#173D24` | Display text (Hijri date), primary headings |
| `h.green800` | `#1D3D28` | Overline text (weekday) |
| `h.cardGradStart` → `h.cardGradEnd` | `#396C4B` → `#234930` (left to right in LTR) | Quran hero card **only** |
| `h.greenChip` | `#456852` | Chevron circle on green cards |
| `h.dhikrOverlay` | `#12261A` → `#1D3424` | Overlay on the dhikr photo |
| `h.gold` | `#D4A847` | Dot accent (decorative, not text) |
| `h.goldLabel` | `#DEBE6B` | Gold overline text on dark green |
| `h.goldRule` | `#CCAC55` | Short rule before gold labels |
| `h.text` | `#050B07` | Tile titles, body text |
| `h.textMuted` | `#5F615E` | Subtitles, overlines on light surfaces |
| `h.textDate` | `#575D59` | Gregorian date |
| `h.tileCool` / `h.tileCoolChip` | `#FBFDFA` / `#EAF4EB` | Feature tiles, green family |
| `h.tileWarm` / `h.tileWarmChip` | `#FDFAF3` / `#FBF0DE` | Feature tiles, warm family |

### 2.2 Identity R: Reader, drawer and menus (screenshots 02–06)

| Token | Value | Role |
|---|---|---|
| `r.bar` | `#20474C` | App bar, overflow menu background |
| `r.onBar` | `#FFFFFF` | Icons and text on `r.bar` |
| `r.icon` | `#19494D` | Drawer icons on white |
| `r.surface` | `#FFFFFF` | Drawer, bottom sheets |
| `r.text` | `#1D1D1D` | Drawer and sheet primary text |
| `r.textSecondary` | `#828284` as measured; **`#737375` proposed** (see §11) | Secondary label text in sheets |
| `r.divider` | `#E2E2E2` | Dividers |
| `r.pageDark` | `#000000` | Reading page, dark mode |
| `r.inkDark` | `#FFFFFF` | Quran and book text, dark mode |
| `r.ayahMarker` | `#557560` | Ayah rosette (if drawn by us rather than the font) |
| `r.highlight` | `#857460` | Selected ayah or passage background |
| `r.pageLight`, `r.inkLight` | **Not in the references** (the light mode in screenshot 06 isn't shown) | Gap G-09 |

### 2.3 Semantic colours (Proposed, not in the references)

| Token | Value | Use |
|---|---|---|
| `s.verified` | `#2E6B47` (on light surfaces) | "Verified" badge |
| `s.draft` | `#8A6A1F` | "Draft (AI)" and "Needs verification" badges |
| `s.error` | `#A63F3F` | Failed downloads, validation errors |
| `s.offline` | `#19494D` (`r.icon`) | Downloaded / available offline |
| `s.playingSpan` | `r.highlight` at 100% for the passage being **read**; at 55% for the passage being **explained** | Synced reader (Proposed; the Sheikh's reading and explanation must look different) |

### 2.4 Dark mode

The Reader identity already has a dark page (screenshot 03). **The Home identity has no dark reference** (gap G-10). Proposed: Home and browse surfaces follow the system theme only once a dark Home design is approved. Until then the reading surfaces offer dark and light, and browse surfaces stay light.

---

## 3. Typography system

### 3.1 Families

| Use | Family | Status |
|---|---|---|
| Latin UI | Looks like **Inter** (single-storey "a", the shape of the digits) | ASSUMED; confirm (G-08). Inter is SIL OFL |
| Arabic UI | **Noto Sans Arabic** or IBM Plex Sans Arabic: a sans to pair with Inter | Proposed (G-11) |
| Arabic content (Tafsir, books, dhikr) | **Noto Naskh Arabic** or **Amiri** (both SIL OFL) | Proposed; the dhikr in 01 is set in a Naskh |
| Quran, continuous mode | KFGQPC Uthmanic Hafs or another licensed Uthmani font that matches the text's encoding | BLOCKED on licence (QURAN_AND_AUDIO_ACCURACY §2) |
| Quran, mushaf page mode | QPC per-page fonts for the same edition as the layout data | BLOCKED on licence |

### 3.2 Scale (measured from 01, 02 and 05; sizes in sp)

| Style | EN size / weight / tracking | AR size (≈ +12%) | Line height (EN / AR) | Example |
|---|---|---|---|---|
| `display` | 20 / 700 / 0 | 22 | 1.25 / 1.5 | Hijri date |
| `title` | 20 / 700 / 0 | 22 | 1.25 / 1.5 | "Quran" on the hero card |
| `tileTitle` | 18 / 700 / 0 | 20 | 1.25 / 1.5 | "Khatmah" |
| `body` | 15 / 400 / 0 | 17 | 1.6 / 1.8 | Dhikr translation |
| `bodySmall` | 14 / 400 / 0 | 16 | 1.45 / 1.7 | Tile subtitles |
| `listItem` | 16 / 400–500 / 0.2 | 18 | 1.3 / 1.5 | Drawer and sheet rows |
| `overline` | 12 / 600 / +1.5 to 2 (caps) | 13 / 600 / **0, no caps** | 1.3 / 1.5 | "EXPLORE", "DHIKR OF THE DAY" |
| `caption` | 12–13 / 400 / 0 | 14 | 1.4 / 1.6 | Gregorian date |

**Arabic rules:** Arabic has no capital letters, and letter-spacing breaks the joins between letters. So in Arabic the **caps and tracking are removed** from overlines, and weight carries the emphasis instead. Arabic sizes are about 12% larger so the visual size matches Latin.

### 3.3 Reading text (Proposed)

| Text | Default | Range | Line height |
|---|---|---|---|
| Quran, continuous mode | 28 sp | 20–44 sp, in 2 sp steps | 2.0–2.2 |
| Quran, page mode | Fit to page width; pinch-to-zoom keeps the page's own line breaks | — | From the font edition |
| Arabic Tafsir and book text | 20 sp | 16–32 | 1.9 |
| English translation and explanation | 16 sp | 14–24 | 1.6 |
| Somali transcript of the Sheikh | 16 sp | 14–24 | 1.6 |

Quran text never shrinks below 20 sp in continuous mode, whatever the system text scale.

---

## 4. Spacing, shape and elevation

| Token | Value | Source |
|---|---|---|
| Base grid | 4 dp | Proposed |
| `space.gutter` | 24 dp | Measured (34 px) |
| `space.cardGap` | 14 dp, between hero cards and between tiles | Measured (20 px); confirm |
| `space.cardPadding` | 22 dp | Measured (about 31 px) |
| `space.section` | 24 dp above a section label | Measured |
| `size.drawerRow` | 48 dp | Measured (67.5 px pitch) |
| `size.appBar` | 56 dp | Measured (about 74 px under the status bar) |
| `size.touchMin` | 48 × 48 dp | WCAG / Material |
| `size.drawerWidth` | about 289 dp (75% of the width) | Measured (406 px); Material's default is 304 dp, see P-13 |
| `radius.card` | 16 dp | Measured (about 22 px) |
| `radius.banner` | 12 dp | Measured (drawer banner) |
| `radius.sheet` | 16 dp, top corners | Measured |
| `radius.chip` | Fully rounded | Measured |
| `elev.card` | Shadow at y = 4, blur 16, 8% black | Estimated from 01 |
| `elev.tile` | 1 px border `#E6E9E6` + shadow at y = 1, blur 4, 4% black | Estimated from 01 |
| Hero card sizes | Dhikr card about 336 × 277 dp; Quran card about 336 × 106 dp; medallion about 60 dp | Measured |
| Feature tile | about 160 × 179 dp | Measured |

---

## 5. Component system

| Component | Identity | Source | Notes |
|---|---|---|---|
| `DateHeader` (overline with dot, Hijri date, Gregorian date) | H | 01 | The Hijri method must be named (QURAN_AND_AUDIO_ACCURACY §3.6) |
| `DhikrCard` (photo, overlay, gold label row, Arabic, divider, translation, reference) | H | 01 | Adds a **source reference line**, required by the accuracy rules; this deviation is listed in §11 |
| `HeroCard` (medallion, title, subtitle, chevron chip, gradient) | H | 01 | The gradient is reserved for Quran |
| `SectionLabel` (overline + hairline rule to the end) | H | 01 | |
| `FeatureTile` (illustration, title, subtitle, chevron chip; cool or warm) | H | 01 | Illustration slot: placeholder until assets arrive |
| `AppDrawer` (header with medallion and name, rows, banner, footer rows) | R | 02 | |
| `ReaderAppBar` (menu, truncated title, actions, overflow) | R | 03 | |
| `SurahHeader` (ornamental frame + name) | R | 03 | Needs an asset |
| `AyahActionSheet` (handle, two-tone rows, divider) | R | 05 | |
| `OverflowMenu` (teal popup) | R | 06 | |
| `ContentBadge`: Quran · Tafsir · Sheikh · Translation · Note · Draft (AI) · Verified | Both | **Proposed** | Quiet text chips with an icon and a label; colour is never the only signal |
| `BookCover` (cover image, or a typographic fallback built from the title; never an invented image) | H | Proposed | |
| `BookRow` / `BookCard` | H | Proposed | |
| `DownloadButton` (states: not downloaded → queued → progress → paused → downloaded → failed → update available) | Both | Proposed | |
| `StorageBar` | H | Proposed | |
| `MiniPlayer` (title, play/pause, progress hairline) | R | Proposed | |
| `PlayerControls` (back 10 s, play/pause, forward 10 s, speed, sleep timer, queue) | R | Proposed | |
| `SpanTimeline` (spans by kind along the recording) | R | Proposed | |
| `StateView` (loading skeleton, empty, offline, error with retry) | Both | Proposed | |

---

## 6. English and Arabic layout rules

1. **Locale drives direction.** Use `MaterialApp` with `localizationsDelegates` and `supportedLocales: [en, ar]`, and let `Directionality` come from the locale. Never wrap a whole screen in a flipped transform.
2. **Directional APIs only:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start` and `.end`. A lint or code review rejects `left` and `right` in layout code.
3. **Mirroring icons:** directional icons mirror (back, forward, chevrons, the drawer-side menu affordance). Icons that show real-world objects or time **don't mirror**: play, pause, the clock, download, and the media progress and seek direction (Material bidi guidance; confirm during Phase 1).
4. **Content direction is set by the content, not the UI language.**
   - Quran, Arabic Tafsir and Arabic book text are **always RTL**, even in the English UI.
   - English translation is **always LTR**, even in the Arabic UI.
   - Somali transcripts are LTR.
   - Each content block sets its own `textDirection`. Mixed inline text (for example an English book title inside an Arabic sentence) uses bidi isolation at **render time**. **Bidi control characters are never inserted into stored religious text.**
5. **Mushaf paging** follows the physical mushaf in both UI languages: the next page comes from the left (a reversed `PageView`).
6. **Digits** (pending P-14): Arabic UI uses Arabic-Indic digits (٠١٢…) or Western digits? Ayah numbers inside mushaf rosettes come from the font. Time codes in the player use Western digits in both languages (Proposed, for legibility).
7. **Dates:** Hijri month names come from a reviewed localisation table, not from machine translation.
8. **Text expansion:** English labels can become about 30% longer or shorter in Arabic. Tiles and buttons must wrap to two lines rather than clip.
9. **Translation of interface strings:** Arabic UI strings are reviewed by a native speaker before release. **Religious content is never machine-translated** (spec §4).
10. **Testing:** every screen gets golden screenshots in EN-LTR and AR-RTL, at text scales 1.0 and 2.0 (§9).

---

## 7. Navigation system

- **Primary:** the **drawer** (screenshot 02), which opens from the start edge. There is **no bottom navigation bar**, because the references have none.
- **Hub:** Home (01). Its hero cards and feature tiles are the entry points.
- **Proposed drawer structure** (G-12). It keeps all existing rows and adds a "Library" group:
  Home · **Library** · **Sheikh's Lessons** · **Tafsir** · **Downloads** · Recent Page · Index & Bookmark · My Notes · Itqan · Statistics · Recitation Correction · [banner] · Learn How to Use · Settings · About · Live Chat
- **Proposed Home additions:** below the Quran card, a second hero card for "Kutubta Sheekh Calinuur" (the Sheikh's books) **only if approved**. The other new features become feature tiles in the existing grid, in the same style.
- **Routing (go_router):** `/` Home · `/quran` (surah and juz index) · `/quran/page/:n` · `/quran/surah/:s/ayah/:a` · `/library` · `/library/collection/:id` · `/book/:id` · `/book/:id/read?page=` · `/tafsir/:id/passage/:pid` · `/lessons` · `/lesson/:id?t=` · `/downloads` · `/bookmarks` · `/settings` · `/about`. Deep links resolve offline whenever the content is local.
- **Back behaviour:** system back closes sheets, then menus, then the drawer, before leaving the screen. The reader position is kept.

---

## 8. Screen-by-screen specifications

Format for each screen: **Ref** = the reference screenshot, or "concept" if none exists · **Id** = identity · purpose · hierarchy · components · interactions · states · RTL.

### 8.1 Splash. Ref: none (concept). Id: H.
- **Purpose:** show the brand while local databases open (no network needed).
- **Hierarchy:** medallion logo (placeholder until supplied) → "Sheekh Calinuur" → small tagline (wording pending).
- **Interactions:** none. It shows for at least 400 ms and at most until the first frame of Home is ready. The native Android 12+ splash uses the same colours.
- **States:** if a database migration takes over 1.5 s, show "Preparing your library…" with progress. If the migration fails, offer a recovery screen and **never delete user data**.
- **RTL:** centred; the name appears in the active UI language.

### 8.2 Home. Ref: 01 (top part only). Id: H.
- **Purpose:** a daily anchor and a hub to every feature.
- **Hierarchy:** menu button → `DateHeader` → `DhikrCard` → Quran `HeroCard` → "EXPLORE" `SectionLabel` → `FeatureTile` grid (Khatmah, Prayer Times & Qibla, …more below the fold; G-13).
- **Interactions:** tapping the Quran card opens the Quran index or resumes the last page (P-15). Tiles open their features. A long press on the dhikr opens share and copy, including its reference.
- **Loading:** content is local, so there is no spinner; the dhikr shows a skeleton for at most one frame.
- **Empty:** if no verified dhikr is available, the card shows the Quran card's medallion and "Dhikr unavailable" instead of unverified text.
- **Error:** none blocking.
- **RTL:** the menu sits at the start (right). The tile grid order mirrors. The gradient direction mirrors so the darker end stays at the end. The dhikr Arabic stays centred, and the translation block follows the UI language.

### 8.3 Navigation drawer. Ref: 02. Id: R.
- **Hierarchy:** header (medallion + name, "Sheekh Calinuur") → primary rows → banner → secondary rows.
- **Interactions:** the active row is tinted (Proposed: `r.icon` at 8%). The drawer closes on navigation.
- **States:** rows for features that aren't built yet are hidden behind a feature flag. The decision on "Recitation Correction" and "Live Chat" is G-07.
- **RTL:** opens from the right; icons sit at the start.

### 8.4 Quran reader. Ref: 03, 04, 05, 06. Id: R.
- **Purpose:** comfortable, accurate Quran reading in **page mode** (mushaf) and **continuous mode**.
- **Hierarchy:** `ReaderAppBar` → page (surah header frame, text, ayah markers) → optional mini player.
- **Interactions:**
  - Tap the page to show or hide the chrome.
  - Swipe to turn pages, in mushaf direction.
  - Long press an ayah to highlight it (`r.highlight`) and open `AyahActionSheet`: Play to the end of the surah · Play Tafsir · Play Recitation + Tafsir · Add Note · Add Itqan · Tafsir · Bookmark · Copy · Share.
  - Overflow menu: Search · Controls · Go To Page · Light mode.
  - **Copy and Share** copy the exact stored text plus a reference ("Al-Fatiha 1:6"), never a re-typed version.
- **States:**
  - Text not verified → a notice in place of the text (accuracy rule).
  - Page mode licence not cleared → only continuous mode is offered.
  - "Play Tafsir" is shown **only when a verified Sheikh mapping exists** for that ayah; otherwise it's disabled with an explanation.
- **RTL:** the app bar mirrors. The Quran text is RTL in both languages. The sheet's labels follow the UI language.

### 8.5 Surah and Juz navigation. Ref: none (concept). Id: R chrome, white list.
- **Hierarchy:** tabs (Surah · Juz · Pages · Bookmarks) → search field → list.
- **Surah row:** number in a rosette, transliterated name with the English meaning, Arabic name, ayah count, Makki/Madani, start page. All values come from the source metadata.
- **Interactions:** tap opens the surah's start. Search matches English names, Arabic names (normalised) and surah numbers.
- **States:** always available offline (the Quran is bundled).
- **RTL:** the Arabic name leads at the start; numbers follow P-14.

### 8.6 Islamic book library. Ref: none (concept). Id: H.
- **Purpose:** browse a growing collection.
- **Hierarchy:** title → search field → collection chips (Sheikh Calinuur's books · Tafsir · Hadith · Fiqh · Aqeedah · Seerah · History · Arabic Language · Quran Sciences · Education · Other) → "Kutubta Sheekh Calinuur" shelf (horizontal) → "Continue reading" → full list with filters (language, author, downloaded, completed).
- **Book card:** cover or a typographic fallback, title (original script), author, language, status badges (Downloaded, Audio, Synced).
- **States:**
  - Loading: skeleton rows.
  - **Empty:** "No books yet. Books appear here once they're published." (true today).
  - Offline: only downloaded books show, with the note "Showing downloaded books. Connect to see the full library."
  - Error: inline retry.
- **RTL:** shelves scroll from the start; the filter sheet mirrors.

### 8.7 Book details. Ref: none (concept). Id: H.
- **Hierarchy:** cover → title (original + English) → author, Sheikh, edition, publisher (shown only when known; **missing metadata says "Not recorded"**, never a guess) → status row (pages, volumes, lessons, audio, transcript, sync status) → primary action (Read / Continue) → `DownloadButton` with the package size → volumes and chapters list with per-chapter lesson indicators → rights and source panel.
- **States:** if rights don't allow offline use, the download is hidden and a reason is shown. Partial download per volume.
- **RTL:** mirrors; Arabic titles render RTL in both UIs.

### 8.8 Book reader. Ref: none (concept). Id: R.
- **Modes:** **Original page** (PDF or scan, always available) · **Text** (when extracted text is verified; unverified OCR text shows a "Needs verification" banner and a one-tap switch to the page image).
- **Hierarchy:** `ReaderAppBar` (title, table of contents, search, bookmark, overflow) → page → bottom scrubber (page n of N).
- **Interactions:** select text → highlight, note, copy with citation. Table-of-contents jump. In-book search lists hits with context. Text mode has a font-size control.
- **States:** a missing local file triggers a re-download prompt, never a silent failure.
- **RTL:** page order follows the book's script (an Arabic book pages from the right), whatever the UI language.

### 8.9 Tafsir reading screen. Ref: none (concept). Id: R.
- **Hierarchy:** ayah block (verified Quran text with its reference) → **Tafsir passage**, labelled with the source, volume and page → (if one exists) **"Sheikh Calinuur's explanation"** block with a play button, visually distinct (different background and a badge) → translation of meanings (labelled) → editorial notes (labelled) → footnotes.
- **Interactions:** previous and next ayah range. "Listen to the explanation" seeks to the mapped span. Font size control.
- **States:** no Tafsir for this ayah → say so plainly. Tafsir not downloaded → offer the download.
- **RTL:** the Arabic blocks are always RTL. The English blocks follow their own direction.

### 8.10 Sheikh lesson library. Ref: none (concept). Id: H.
- **Hierarchy:** filter by book → book groups → lessons (number, title, duration, progress ring, badges: Downloaded · Transcript · Synced).
- **States:** empty ("No lessons published yet"). Offline: downloaded lessons only.
- **RTL:** mirrors.

### 8.11 Sheikh audio player. Ref: none (concept). Id: R.
- **Hierarchy:** **"Original recording" badge** → lesson title and book → current passage preview (if synced) → `SpanTimeline` → time codes → controls → speed · sleep timer · queue · download.
- **Background playback:** lock-screen and notification controls through `audio_service`. Sheikh lessons and Quran recitation are **separate categories** with different icons and labels.
- **States:** buffering, offline and not downloaded ("Download to listen offline"), rights don't allow streaming.
- **RTL:** controls are **not mirrored** (§6.3); the labels mirror.

### 8.12 Audio-synchronised Tafsir reader. Ref: none (concept). Id: R.
- **Purpose:** follow the passage the Sheikh is reading or explaining.
- **Hierarchy:** passage list (Tafsir passages with their ayah references) → mini player docked at the bottom → current-span indicator ("Reading" or "Explaining").
- **Highlight rules:**
  - A `reading` span gives the passage full `s.playingSpan`.
  - An `explanation` span gives the passage a lighter tint plus a side bar, with the Somali transcript snippet if it's verified.
  - Gaps, `intro` and `qa` spans highlight nothing.
  - Stale or unverified mappings highlight nothing.
- **Auto-follow:** the active passage is kept in the upper third of the screen. If the user scrolls by hand, auto-follow pauses and a "Return to current" chip appears.
- **Interactions:** tap a passage to seek to its first `reading` span (or its first span if there's no reading span). Seeking updates the highlight within 1 frame of the new position.
- **States:** no verified mapping → it works as a normal player plus reader, with the note "This lesson isn't synchronised yet."
- **RTL:** the list is RTL for Arabic Tafsir; the chip and player labels follow the UI.

### 8.13 Downloads. Ref: none (concept). Id: H.
- **Hierarchy:** `StorageBar` (used by the app / free on the device) → active queue (cover, title, part being fetched, bytes, progress, pause, resume, cancel) → completed (size, date, remove) → failed (reason, retry) → "Download all authorised books" (shows the total size first and asks for confirmation).
- **States:** "Waiting for Wi-Fi" (setting), "Not enough storage" (shows the space needed), "Update available" (delta size).
- **Notice:** "Uninstalling the app or clearing its data removes downloads" (master prompt §7.5).
- **RTL:** mirrors; progress bars fill from the start.

### 8.14 Offline library. Ref: none (concept). Id: H.
- **Purpose:** everything usable right now without internet.
- **Hierarchy:** sections: Quran (always) · Books · Tafsir · Lessons. Each item shows what's included offline (text / audio / sync).
- **Empty:** "Nothing downloaded yet." with a link to the Library.
- **RTL:** mirrors.

### 8.15 Bookmarks and reading history. Ref: none (concept); related to the drawer's "Index & Bookmark", "Recent Page" and "My Notes". Id: R chrome.
- **Tabs:** Bookmarks · Notes · Highlights · History. Each item shows its content-type badge, reference (ayah, page, timestamp) and date.
- **Interactions:** swipe to delete, with undo. Tap to jump to the exact position. History groups by day.
- **States:** empty for each tab, with a hint on how to add items.
- **RTL:** the swipe direction mirrors.

### 8.16 Settings. Ref: none (concept). Id: R chrome, white list.
- **Groups:**
  - Language (English / العربية)
  - Reading: theme, Quran font size, translation on or off, page or continuous mode
  - Audio: default speed, sleep timer
  - Downloads: Wi-Fi only, storage location if supported, clear cache (never user data)
  - Hijri date: method, ±days
  - Notifications
  - Account (optional sync)
  - Content sources and licences
  - About
- **RTL:** switches show on the end side.

### 8.17 About Sheekh Calinuur. Ref: none (concept). Id: H.
- **Hierarchy:** medallion → name → short description (**owner-supplied text only**) → about the Sheikh (owner-supplied; **no invented biography, no portrait** unless supplied) → content sources and attributions (Tanzil, translation, fonts, Quran Foundation if used) → app version → contact.
- **RTL:** mirrors.

---

## 9. Interaction and animation guidelines

| Use | Duration | Curve | Notes |
|---|---|---|---|
| Show or hide reader chrome | 200 ms | Material standard | Fade + slide |
| Bottom sheet | 250 ms in, 200 ms out | Emphasised decelerate / accelerate | |
| Ayah or passage highlight on/off | 120 ms | Linear fade | Never animates position |
| Auto-follow scroll in the synced reader | 300 ms | Ease in-out | Only when the active passage leaves the comfort zone |
| Page turn (mushaf) | Physics-driven swipe | — | No page-curl effect |
| Download progress | Continuous | — | Throttled to at most 4 updates a second |

- **Reduced motion:** honour `MediaQuery.disableAnimations`. Turn transitions into cross-fades and auto-follow into jumps.
- **Haptics:** a light tick on long-press selection only.
- **No animation that loops on its own**, except progress and buffering indicators.

## 10. Accessibility guidelines (target: WCAG 2.1 AA)

- **Contrast**, checked on the measured pairs: hijri date 10.2:1 · tile subtitle 6.0:1 · gold label on dark 7.5–8.9:1 · white on teal bar 10.2:1 · white on the highlight 4.5:1 (borderline). **Failures:** sheet secondary text `#828284` on white is **3.84:1** (needs 4.5) → `#737375` (4.73:1). The Quran card subtitle at about 70% white on `#396C4B` is about **4.0:1** → 80% white (4.62:1). See §11.
- **Touch targets** of at least 48 × 48 dp. The tiles' chevron chips are decorative, and the whole tile is the target.
- **Text scaling** up to 200% without clipping. Tiles grow taller, and the app bar title truncates with a tooltip.
- **Screen readers:**
  - Every icon button has a label in both languages.
  - Ayahs announce "Surah Al-Fatiha, ayah 6" before the text.
  - Content badges are read out ("Verified", "Draft, not reviewed").
  - The synced reader announces passage changes only on user request (otherwise it would interrupt the audio).
- **Colour is never the only signal:** reading versus explaining spans use a tint **plus** a side bar and label; download states use an icon plus text.
- **Focus order** follows the reading direction in both languages.

## 11. Deviations from the references (proposed, with reasons)

| # | Deviation | Reason | Owner decision |
|---|---|---|---|
| DV-01 | Sheet secondary text `#828284` → `#737375` | Contrast 3.84 → 4.73:1 (WCAG AA) | P-16 |
| DV-02 | Quran card subtitle opacity about 70% → 80% | Contrast about 4.0 → 4.6:1 | P-16 |
| DV-03 | A source reference line added to the Dhikr card | Accuracy rule: no dhikr without its reference | P-12 |
| DV-04 | Drawer header name "Quran Tabsera" → "Sheekh Calinuur" | Official name | Confirmed |
| DV-05 | New drawer rows (Library, Lessons, Tafsir, Downloads) | Required features | P-17 (G-12) |
| DV-06 | Arabic overlines without caps or tracking | Arabic script rule | Recommended |
