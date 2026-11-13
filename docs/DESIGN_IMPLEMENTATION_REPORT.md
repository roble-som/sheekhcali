# Design implementation report: Phase 1, first increment

Date: 2026-11-13. Scope (C-15): the foundation, design tokens, reusable components, navigation, and the Splash, Home, Drawer and Quran Reader screens, in English (LTR) and Arabic (RTL).

**Evidence labels:** VERIFIED (directly confirmed) · PARTIALLY VERIFIED · NOT TESTED · BLOCKED.

## How the screens were compared

1. Golden tests (`test/goldens/reference_screens_golden_test.dart`) render the real app at **exactly the reference geometry**: 540 × 1170 px at 1.40625 px/dp, a 50 px status bar inset and a 67.5 px navigation bar inset. They use the bundled fonts and the reference date, Thursday 12 November 2026.
2. `python3 -I tool/compare_with_references.py` writes `docs/design/comparison/*.png`: **reference | Flutter | 50% overlay**. Ghosting in the overlay shows misalignment.
3. Sizes were calibrated by comparing text widths in pixels (DESIGN_TOKENS.md). After calibration, the hijri date (366 px) and the tile title (102 px) match exactly; the other measured texts are within 6 px.

The status bar and navigation bar are drawn by the system, so they are blank in the goldens.

## Results by reference

| Reference | Result | Remaining differences | Label |
|---|---|---|---|
| 01 Home | Header, dhikr card, Quran card, EXPLORE and tiles line up in the overlay to within about 3–5 px vertically and 1–6 px in measured widths | (a) Dhikr Arabic, translation and photo are **placeholders** (P-12 and photo rights). (b) Logo medallion and tile illustrations are **placeholders** (P-02). (c) A dhikr reference line is added (DV-03). (d) Two extra tiles (Library, Sheikh's Lessons) appear below the fold (approved §7; order pending G-13) | VERIFIED by overlay |
| 02 Drawer | Header height, divider, 48 dp rows and icon and label columns line up within about 2 px | (a) Name changed to Sheekh Calinuur (DV-04). (b) Four approved rows inserted (DV-05), so everything from "Recent Page" down is shifted by 4 rows. (c) Logo and banner contents are placeholders. (d) Some icons are Material substitutes (COMPONENT_MAPPING) | VERIFIED by overlay |
| 03 Reader | App bar: icon positions within about 2 px, height exact. Page: surah header and line rows line up | (a) **No Quran text**: hatched layout blocks and the "Layout preview · not Quran text" notice (accuracy rule). (b) Surah ornament is a placeholder | VERIFIED by overlay |
| 04 Ayah selected | The highlight covers both line segments of the selected ayah across the line break, at the reference's positions | Placeholder blocks instead of text | VERIFIED by overlay |
| 05 Action sheet | Sheet top, handle, all 9 rows (52 dp) and the divider line up within about 1 px | Icon substitutes for Add Note, Copy and Share | VERIFIED by overlay |
| 06 Overflow menu | Position, width (167 dp), 48 dp rows and teal colour match | Icon substitute for Go To Page; Arabic labels may widen the menu up to 257 dp | VERIFIED by overlay |

## Arabic (RTL)

Goldens `*_ar.png` checked visually and by tests:
- Drawer opens from the right, at x = 95–384.
- The menu button is at the start (right) edge; the overflow button is at the end (left).
- Chevrons mirror. Play and other media icons don't.
- The **Quran page stays RTL with identical line structure** in both languages.
- Overlines have no caps or tracking.
- Arabic-Indic digits are used (P-14 default).
- The menu shows full Arabic labels.

## Accessibility

- Contrast is tested for all 17 text pairs (`test/core/contrast_test.dart`), all ≥ 4.5:1. The test also documents that the measured reference value `#828284` fails, which is why DV-01 exists.
- At 200% text scale there's no overflow in English or Arabic, including after scrolling (tests and goldens `home_*_text200`).
- Every icon button has a tooltip or semantic label in both languages. Placeholders announce "Placeholder: …", and placeholder ayahs announce "Not Quran text".
- Touch targets are ≥ 48 dp. In the reader app bar the action buttons are 40 dp wide, as measured, but 48 dp tall. **The 40 dp width matches the reference but is below the 48 × 48 target.** This is recorded as deviation candidate DV-07 for the owner.
- Reduced motion: the reader chrome animation becomes instant when animations are disabled.

## Real-device validation (Android emulator)

Debug APK on the `Medium_Phone_API_37.0` emulator (Android API 37, 1080 × 2400, 420 dpi, so 411 dp wide), driven with adb. Screenshots are in `docs/design/screenshots/emulator/` (01–13).

| Check | Result | Label |
|---|---|---|
| Launch, splash and Home with the live date (Friday 13 Nov 2026 = 3 Jumada al-Thani 1448) | OK | VERIFIED |
| Drawer, reader, ayah long press and sheet, overflow menu, Settings | OK | VERIFIED |
| Language switch to Arabic in Settings; Arabic Home, drawer, reader, sheet and menu | OK, fully RTL | VERIFIED |
| **System back with the drawer open** | **Bug found:** the app closed. On Android 16 (target SDK 36) predictive back needs the framework to report that it handles back, and Scaffold's drawer doesn't report it. **Fixed** with `DrawerBackScope` (a `PopScope`). Re-verified on the emulator: back closes the drawer and stays on Home. Regression test `test/features/back_navigation_test.dart` fails without the fix and passes with it | VERIFIED |
| Android 12+ system launch screen | Uses the `#EBEBE9` background, but shows the **default Flutter launcher icon**: there is no app icon until the logo arrives (P-02) | Open issue |

## Large text

At 200% text the fixed-height dhikr card clipped its placeholder labels. It now keeps the measured 277 dp height up to 1.15× text scale and grows with its content above that (goldens `home_*_text200`).

## Deviations introduced in this increment

| ID | Deviation | Reason |
|---|---|---|
| DV-01, DV-02 | Contrast fixes | Approved (C-16) |
| DV-03 | Dhikr reference line | Accuracy rule |
| DV-04, DV-05 | Name and drawer rows | Approved |
| DV-06 | Arabic overlines without caps or tracking | Arabic script |
| DV-07 (new, owner to confirm) | Reader app-bar actions 40 dp wide (as in the reference) instead of 48 dp | Keeps the reference layout; the alternative would crowd the title |
| DV-08 (new) | "Layout preview · not Quran text" notice on the reader | Accuracy rule: placeholder blocks must not be mistaken for text |
| DV-09 (new) | Overflow menu may widen beyond 167 dp for Arabic | Arabic labels don't fit |

## Not yet done

See the final section of the Phase 1 report in chat and `DEVELOPMENT_ROADMAP.md`.

---

# Phase 1, second increment (2026-11-13)

Scope (owner approval, recorded as C-18 to C-24): the reader toolbar touch targets, Surah and Juz navigation, Library, Book details, and Settings improvements.

## Decisions applied

| Decision | Implementation | Evidence |
|---|---|---|
| C-18: 40 dp visual pitch, 48 × 48 dp touch targets | `ToolbarActionStrip` + `NearestHitArea` (`lib/core/widgets/toolbar_action_strip.dart`). Each reader toolbar button is 48 × 48; neighbouring targets overlap by 8 dp, and a tap in an overlap goes to the nearer icon | `test/features/toolbar_touch_targets_test.dart`: sizes, icon centres (menu 28.4 dp, more 384 − 28.4 dp), and hit routing probed at ±1 and ±3.9 dp around every midpoint, LTR and RTL. **Reader goldens re-ran unchanged (pixel-identical)** |
| C-19 to C-22 | Kept as provisional defaults | — |
| C-23: tile order Library, then Sheikh's Lessons | Already in that order | Home goldens |
| C-24: placeholders labelled | Applied to every new screen | Tests below |

## New screens

| Screen | Identity | Shipped state | Test coverage |
|---|---|---|---|
| Surah and Juz index (`/quran/index`; opened from the reader's index button and the drawer's "Index & Bookmark") | R | **No verified metadata (P-03, P-07)**, so an honest notice plus a labelled layout preview. No surah names, counts or juz boundaries are typed in | Shipped state, plus the full behaviour (lists, search by number, transliteration and harakat-free Arabic, juz starts, Arabic plurals and digits, navigation) against a **synthetic test fixture** with deliberately fake names. The fixture is never bundled |
| Library (`/library`) | H | Honest empty state: "No books yet" (nothing is published) | Empty state; filters; search; navigation; 200% text in EN and AR |
| Book details (`/library/book/:id`) | H | Unknown id → "This book isn't available." | "Not recorded" fields, volumes and chapters, Arabic plurals, honest Read and Download, RTL, 200% text |
| Settings (rebuilt) | R | Language, reading theme, **Hijri adjustment −2…+2 with a live preview** (applied app-wide), Wi-Fi-only preference (marked as taking effect once downloads exist), Content sources, About, and a debug-only Developer group | Adjustment persists and changes Home; Wi-Fi pref stored; Arabic signed digits; 200% text |
| Content sources & licences (`/settings/sources`) | R | States that the Quran text, index, translation and books are **not installed** or **not published**; lists the Hijri table and font licences; opens Flutter's licence page with the bundled font licences registered | Test |

**Design preview data (debug builds only).** A Settings → Developer switch loads a placeholder catalogue so the Library and Book details screens can be reviewed. Every title is "Preview book N" / "كتاب معاينة N", every unknown field reads "Not recorded", each item carries a "Preview" badge, and the Library shows a banner "Design preview data · not real books". It holds no religious text. `kDebugMode` gates it, so release builds can never enable it.

## Defects found and fixed during validation

1. The Library shelf's fixed height overflowed (tests). The shelf is now sized by its content.
2. `SectionLabel` overflowed at 200% text with long labels. It now measures the label: the reference layout when it fits, otherwise a wrapped label without the rule. The Home goldens stayed pixel-identical.
3. Book details Read and Download clipped at 200% text. They now stack above 1.3× text scale.
4. Shelf badges truncated "Preview" at 200%, which would hide the preview marker. The shelf items now grow with the text scale.
5. List rows were crowded (up to 5 badges). Rows now show compact badges; details keep the full set.

## Accessibility notes

- The placeholder ayah lines in the reader are 33.4 dp tall (the measured line pitch), below 48 dp. This is the WCAG 2.5.8 **inline** exception: targets constrained by the line height of text. Recorded here rather than altering the measured layout.

## Real-device validation, increment 2 (Android emulator, API 37)

Screenshots are in `docs/design/screenshots/emulator/increment2/` (01–15, English and Arabic).

| Check | Result | Label |
|---|---|---|
| Reader index button opens the Surah/Juz index; Juz tab | OK, EN and AR | VERIFIED |
| Drawer → Library (empty state) | OK, AR | VERIFIED |
| Settings: language switch, Hijri method and adjustment with live date, Wi-Fi switch, Developer → design preview | OK, EN and AR | VERIFIED |
| Library with design preview (banner, shelf, compact badges) → Book details | OK, EN and AR | VERIFIED |
| Emulator note | The first cold boot hung with `adb shell` unresponsive after an earlier forced shutdown had left stale AVD lock files. A clean restart booted in about 40 s. The emulator is now shut down with `adb emu kill` | — |

---

# Al-Fatiha and the Sheikh's Tafsir audio (2026-11-13)

Owner decisions: C-25 (Tanzil Uthmani 1.1 approved), C-26 (R3 is the Sheikh's Tafsir of Al-Fatiha, testing only), C-27 (owner is the reviewer), C-28 (local draft transcript allowed).

## What is built

| Part | Implementation | Evidence |
|---|---|---|
| Quran text import | `tool/quran/import_tanzil.dart` validates the whole Tanzil file (6,236 ayahs, contiguous, per-surah counts equal to the metadata, no control characters), extracts Al-Fatiha verbatim with per-ayah SHA-256, stores the licence block verbatim, and runs an independent letter-skeleton cross-check (Quran Foundation `text_uthmani`: 7 of 7 match) | `assets/quran/tanzil-uthmani-1.1/surah-001.json`, `test/quran/surah-001.manifest.json` |
| Text accuracy tests | Exact text against the independent manifest, round trip to the exact source lines, source checksum, order and numbering, basmala = ayah 1 (from the source), licence, cross-check, no normalisation, **tamper test** (one changed mark → the text is refused), font glyph coverage (Amiri covers all 32 code points) | `test/quran/al_fatiha_text_test.dart` (12 tests) |
| Load-time integrity | `BundledQuranTextRepository` re-hashes every ayah on load and fails closed (labelled layout preview, no text) | `quran_reader_test` "fails closed" |
| Reader | Continuous Uthmani text (Amiri, 28 sp, line height 2.15, RTL, centred), surah header from the metadata name, ayah-end rings with Arabic-Indic numbers, meta line, Tanzil attribution and link, reviewer-status chip, source dialog with the verbatim licence. Copy = exact stored text + reference. Identical text in the EN and AR interfaces | Display-path test: the spans handed to the renderer equal the stored strings byte for byte, in both languages |
| Recording handling | Identified by SHA-256, **not bundled** (C-26). Debug builds play a locally installed copy only after re-hashing it on the device; release builds can't play it (`RecordingNotPermitted`) | Tests + emulator (copy hash on device = original) |
| Player | just_audio + audio_service: play/pause, seek bar, ±10 s, position/duration, loading/buffering/completed/error states, background playback, notification and lock-screen controls. MP3 **index seeking** for this VBR file. Labelled "Sheikh's Tafsir · original recording" / "Explanation, not Quran recitation" / "Testing only" | Widget tests with a fake player; emulator (below) |
| Synchronisation | Spans bound to the recording SHA-256 and to each ayah's text SHA-256; kinds reading/explanation/intro/qa; many ayahs per span; validator (overlap, range, end, ayah bounds, signed); binary-search lookup; tap an ayah → its first reading span. **Only verified, signed, valid, fresh spans highlight** | `span_index_test` (10), synthetic-mapping widget tests: playing, gaps, draft, seek back and forth, tap-to-seek, Arabic |
| Review workflow | Audacity labels → `tool/alignment/import_labels.dart` (hash-checked, validated, `--sign-off --reviewer`), `tool/quran/sign_off_text.dart`, machine draft labels `tool/alignment/asr_draft_labels.dart`, guide `docs/review/AL_FATIHA_TAFSIR_REVIEW.md` | `labels_test` (6) |

**Live R3 highlighting: none yet, by design.** The bundled R3 alignment has **zero verified spans** until the owner reviews (C-27). The app shows "Ayah highlighting: waiting for review". Highlighting itself is proven with a clearly synthetic test mapping bound to a fake recording hash (goldens `fatiha_sync_SYNTHETIC_*`), which can never apply to R3.

## Real-device validation (Android emulator, API 37)

Screenshots: `docs/design/screenshots/emulator/fatiha/` (01–08). Screen recording: `fatiha_flow_en.mp4` (68.9 s).

| Check | Result | Label |
|---|---|---|
| Recording copy installed with the guide's adb commands; on-device SHA-256 equals the original | `3300e364…` on both | VERIFIED |
| Reader shows Al-Fatiha (Amiri, all marks), EN and AR | OK | VERIFIED (visual; the owner's mushaf comparison is still pending) |
| Play → media session `PLAYING` | position 5.65 s | VERIFIED |
| +10 s then pause → `PAUSED` | position 20.92 s | VERIFIED |
| Home button → playback continues in the background | `PLAYING` 28.4 s → 38.6 s with the launcher in front; foreground service `mediaPlayback` | VERIFIED |
| Notification and lock-screen controls | **Bug found:** hidden, because POST_NOTIFICATIONS (Android 13+) was never requested. **Fixed:** asked once on first play via a small platform channel. Re-tested from a revoked state: the dialog appears, playback isn't blocked, and after Allow the media card shows "تفسير سورة الفاتحة · Sheikh Calinuur" with controls | VERIFIED |
| Arabic UI on the device | Mirrored chrome, identical Quran text, LTR media controls | VERIFIED |
| Duration | ExoPlayer reports 48:31; the Xing header gives 2,912.0 s (48:32.0). The difference is under 1 s (encoder padding); alignment times use the original timeline | NOTED |
| Seek accuracy in milliseconds (QURAN_AND_AUDIO_ACCURACY §5) | Index seeking is enabled; measuring the error needs audio capture with known markers | NOT TESTED |

## Deviations

| ID | Deviation | Reason |
|---|---|---|
| DV-10 | Continuous reading layout instead of the mushaf page of reference 03 | Mushaf page fonts and layout are blocked on licensing (P-24); continuous mode is the approved fallback (concept 4b) |
| DV-11 | Quran text font is Amiri (OFL), not the KFGQPC font of the references | Same licence block; Amiri covers every code point (tested) |
