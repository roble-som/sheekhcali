# Quran pages, audio and offline: discovery audit (2026-11-13)

Written before any change in this round. Results after the work are in
[QURAN_AUDIO_OFFLINE_FINAL_REPORT.md](QURAN_AUDIO_OFFLINE_FINAL_REPORT.md).

## 1. Repository state

| Item | Found |
|---|---|
| Branch | `main`, working tree clean |
| Latest commit | `a5b83fd` "update and fix all issue" (the owner's commit of the previous round: 327 files) |
| Previous round present? | Yes. All files listed in [APP_AUDIT_2026-11-13 §5](../audit/APP_AUDIT_2026-11-13.md) are in `a5b83fd`: 114 surah assets, `metadata.json`, reading state, search, About, logo assets, tests |
| Differences from the previous report | None found. The previous report said "nothing committed"; the owner committed it afterwards |
| Original recording R3 | `shiiq_mp3/003-الفاتحة 1-آخرها.mp3`, 12,587,299 bytes, SHA-256 `3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f` (measured before any work; equals C-26) |
| Review state | 0 of 7 Al-Fatiha Tafsir segments reviewed (`docs/review/fatiha_review.html`) |
| Toolchain | Flutter 3.47.9, Dart 3.13.7, emulator `emulator-5554` (API 37) |

## 2. What the app means by a "Quran page" today

There is no page concept in the code.

- The reader shows **one whole surah as one paragraph** (`SurahTextView`), centred, in a vertical scroll. Al-Baqarah is a single 286-ayah paragraph.
- No page data is bundled. `metadata.json` holds surahs and juz only.
- "Go to page" in the overflow menu shows "coming later".
- The toolbar title is the Hijri date. No surah, juz or page is shown while reading.
- The bundled Tanzil metadata file (SHA `8867c1d8…`, approved with C-25) **does contain 604 page starts** for the Madinah Mushaf. The importer skipped them.
- Mushaf *line layout* (KFGQPC page fonts) is blocked by licence (P-24). Page *boundaries* are not.

## 3. Findings

| # | Class | Area | Finding | Evidence |
|---|---|---|---|---|
| Q1 | CRITICAL | Pages | No Mushaf pages at all: no page data, no page view, no page numbers, no page navigation | §2 |
| Q2 | HIGH | Pages | "Go to page" is a placeholder | `quran_reader_screen.dart` `_onMore` |
| Q3 | HIGH | Rendering | Long surahs are one huge paragraph. Every tap or selection rebuilds and re-lays out the whole surah. The ring painter measures all 286 markers on each repaint | `surah_text_view.dart` |
| Q4 | MEDIUM | Reader chrome | While reading, nothing shows where you are (surah, juz, page) | Emulator screenshot of Al-Baqarah |
| Q5 | MEDIUM | Index | Juz rows open the right ayah, but nothing links to pages; surah rows show no page | `quran_index_screen.dart` |
| Q6 | LOW | Navigation | Index → reader pushes a new reader on top each time; the back stack grows | `context.push` in the index |
| F1 | — | Font | Amiri Regular covers all 62 distinct characters in the Tanzil text (fontTools check). No missing glyphs | Script in this round |
| P1 | — | Page data | Tanzil pages vs Quran Foundation `page_number` for **all 6,236 ayahs**: 0 differences | QF API v4 `verses/by_chapter`, retrieved 2026-11-13T17:25:48Z |
| A1 | CRITICAL | Audio in installed APKs | An installed APK can never play the Sheikh's recording. **Root cause: policy, not the player.** R3 is "development and emulator testing only, not bundled" (C-26). The debug app looks for `files/dev-media/<sha>.mp3`, which only `tool/device/install_r3.sh` creates over adb. On any other device the reader says "The Sheikh's Tafsir recording isn't installed on this device" | `recording_repository.dart`; emulator screenshot |
| A2 | CRITICAL | Audio in release | Release builds return `RecordingNotPermitted` (`allowTestingOnly = kDebugMode`) | Same |
| A3 | HIGH | Audio, review | With 0 of 7 segments reviewed, playback depends on review mode, which is `kDebugMode` only. A testing build in release mode would play nothing even with the file present | `fatiha_sync.dart` `reviewModeProvider` |
| A4 | MEDIUM | Audio, integrity | A present but corrupted copy is reported, but can't be repaired on the device | `LocalRecordingRepository.locate` |
| A5 | — | Player | The player itself works: an audible check on the emulator passed earlier (9 taps) | DESIGN_IMPLEMENTATION_REPORT |
| O1 | — | Offline | No feature needs the network. `INTERNET` is only in the debug manifest; text, metadata, fonts and logo are bundled; preferences are local | Manifests, pubspec |
| B1 | BLOCKED | Signing | Release is signed with the debug key; no production keystore | `build.gradle.kts` |
| B2 | BLOCKED | Mushaf line layout | Printed page line layout needs KFGQPC fonts (P-24) | PHASE_0_DECISIONS |

## 4. Owner decision taken in this round

Asked and answered on 2026-11-13: **"Testing APK only"**.

- An opt-in build switch may bundle the original R3, unchanged, into a clearly labelled testing APK for the owner's own devices.
- The default build never contains it.
- This extends C-26 (see PHASE_0_DECISIONS).

## 5. Plan

1. Pages: import the 604 page starts from the approved metadata file and cross-check every ayah against Quran Foundation. Add a page reader (604 pages, right-to-left swipe, header with surah and juz, page number, previous/next, go to page).
   - The app's own text flow is used, labelled as such: page *boundaries* are the Madinah Mushaf's, line layout is not (P-24).
   - The continuous surah layout stays as a reading option.
2. Audio: add the opt-in build switch `SHEEKH_TESTING_AUDIO`.
   - Gradle verifies the original's SHA-256 and packs it, uncompressed, as an Android asset.
   - On first need, the app copies it to app-private storage atomically, hashes it while copying, and re-verifies it with the existing check. A corrupt copy is replaced.
   - Testing builds turn on the labelled review mode (P-25).
3. Tests for page data, page navigation, rendering and the extraction path. Then a fresh, offline install of the testing APK on a wiped emulator, with an audible check.
