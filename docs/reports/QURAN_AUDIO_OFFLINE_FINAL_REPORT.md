# Quran pages, offline audio and APK portability: final report (2026-11-13)

Discovery and the plan are in [QURAN_AUDIO_OFFLINE_AUDIT.md](QURAN_AUDIO_OFFLINE_AUDIT.md). Device evidence is in [evidence_2026-11-13/](evidence_2026-11-13/).

## 1. Initial repository status

- Branch `main`, clean, HEAD `a5b83fd` (the owner's commit of the previous round).
- Every change reported in the previous round was present; no differences were found.
- Baseline: `flutter analyze` showed no issues; `flutter test` passed 211 of 211.

## 2. Root cause of the incorrect Quran pages

The app had **no pages at all**:

- No page data was bundled.
- There was no page view and no page number on screen.
- "Go to page" was a placeholder.
- The reader showed each surah as one long paragraph; Al-Baqarah was a single 286-ayah paragraph, rebuilt on every tap.

The approved Tanzil metadata file already contained the 604 Madinah page starts, but the importer had skipped them.

## 3. Quran page fixes

- **Page data.** `tool/quran/import_metadata.dart` now imports the 604 page starts from the approved file and cross-checks them. The app re-checks them at load and fails closed: missing, out-of-order or unrecorded page data disables page mode instead of guessing.
- **Page reader (default layout).**
  - One Madinah page at a time, swiped right to left as in a printed Mushaf, in both interface languages.
  - Each page shows exactly its ayahs, with a surah header and basmala where a surah starts.
  - A running head shows the surah(s) and juz; the footer shows the Mushaf page number in Arabic-Indic digits, between previous and next buttons.
- **Navigation.**
  - Working "Go to page" (1–604, accepts Arabic-Indic digits, rejects anything else).
  - The index, juz rows, bookmarks, search and "continue reading" open the page that holds the ayah and scroll to it.
  - The reading place is saved on page turns, scrolls, taps and long presses.
- **Layout choice.** The previous whole-surah layout is kept as an option in Controls ("Pages / Whole surah"). Switching keeps your place.
- **Honest labelling.**
  - Page *boundaries* are the Madinah Mushaf's. The *line layout* is the app's own, because the printed layout needs the KFGQPC fonts (P-24).
  - The Controls sheet and the source dialog both say so (decision C-30).
- **Fixed while testing:** page-footer chevrons pointed the wrong way in right-to-left layout.

## 4. Quran source and pagination verification

| Check | Result |
|---|---|
| Quran text | Unchanged: Tanzil Uthmani 1.1 (C-25), same asset files as before |
| Page starts | Copied from `quran-data.xml`, SHA-256 `8867c1d8…`, the file approved at C-25 |
| Page of every ayah vs Quran Foundation API v4 `page_number` (retrieved 2026-11-13T17:25:48Z) | **6,236 of 6,236 equal** |
| First and last page of all 114 surahs vs QF `chapters.pages` | All equal |
| Surahs, juz | Byte-identical to before |
| Correction | The earlier cross-check time `19:10Z` was wrong (local time labelled as UTC). It is now `16:00:28Z`, from the files' timestamps |
| `mushaf_pages_test` (12 tests) | Every ayah's page equals the independent record (`test/quran/qf_page_numbers.json`); pages partition the Quran in order; fail-closed cases |
| `all_pages_test` | **All 604 pages rendered** at 3 configurations: phone; 320 dp phone, Arabic, 130% text; tablet, largest text |
| What `all_pages_test` checks on every page | Exact ayahs in order; every number right after its own ayah on the same line; headers and basmala only where a surah starts (none for At-Tawbah); Al-Fatiha's basmala is ayah 1; correct page number; no overflow |
| Goldens | Pages 1, 2, 50, 187 (At-Tawbah), 597 (At-Tin's "بِّسْمِ", then Al-Alaq), 604 (three surahs), and 604 on a small phone at 130% text |
| Font | Amiri covers all 62 distinct characters of the text |

## 5. Audio failure root cause

It was not a player bug. Under C-26 the recording was "never bundled", so **no APK contained it**.

- Debug builds only found a copy pushed over adb by `tool/device/install_r3.sh`.
- Release builds refused it (`kDebugMode` gate).
- Review mode, needed while 0 of 7 segments are reviewed, was also debug-only.

On any other device the reader said "The Sheikh's Tafsir recording isn't installed on this device."

## 6. Audio packaging solution (owner decision C-29: testing APK only)

- **Opt-in switch.** `--dart-define=SHEEKH_TESTING_AUDIO=true`, passed only by `tool/build_testing_apk.sh`.
- **Packing.** Gradle reads the define and checks the original's size and SHA-256, failing the build otherwise. It then packs the file **byte for byte, stored uncompressed**, as the Android asset `testing-audio/<sha>.mp3`.
  - Without the define, nothing is packed and any earlier staging is deleted.
  - Verified: the default debug APK has 0 audio entries.
- **First use on the device.** A native channel in `MainActivity`:
  - checks free space;
  - copies the asset to a `.part` file in app-private storage, hashing it while copying;
  - flushes it to disk and renames it into place only if the SHA-256 and size match.
- **Before playing.** Dart re-hashes the file. A missing, truncated or corrupt copy is replaced; a valid copy is reused.
- **One copy at a time.** Concurrent requests share one copy operation.
- **Clear failures.** Out of space, copy errors and "not packed" each give a plain message.
- **Testing builds** turn on the labelled review mode (P-25). About shows a "Testing build · not for distribution" banner; the player already says "Testing only · not for distribution".
- **Builds without the recording** now say plainly: "This version doesn't include the Sheikh's recording yet: distribution rights are still being confirmed."
- **Bug found and fixed:** a self-await deadlock (`whenComplete` returning the future it was completing) would have left the recording "preparing" forever. A unit test caught it.

## 7. Original recording SHA-256

| When | SHA-256 |
|---|---|
| Before any work | `3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f` |
| Inside the testing APK | Same (`unzip -p … \| sha256sum`) |
| Unpacked on the device | Same (`run-as … sha256sum`) |
| After all work | Same |

The file was only ever read. It was not modified, compressed, trimmed or re-encoded.

## 8. Offline verification (emulator API 37, real install of the testing APK)

`tool/device/fresh_install_check.sh` ran once, end to end ([steps](evidence_2026-11-13/fresh_install_steps.txt), [per-tap results](evidence_2026-11-13/heard_segments.json)):

| Step | Result |
|---|---|
| Uninstall: no app, no data | Done |
| Airplane mode on, Wi-Fi and data off | `ping 8.8.8.8` fails; "Active default network: none" |
| Install | Plain `adb install`; no recording in app storage before launch |
| Launch from the launcher, Quran card | Page 1; player ready within 5 s; device copy SHA-256 equals the original |
| Tap ayahs 1–7 | **All audible (-27 to -29 dBFS)** |
| Where the heard audio comes from | Each tap matched the start of that ayah's segment in the original recording, with 5–6 of 6 windows on the recording's timeline |
| Repeated recitation | Where the Sheikh recites the same ayah earlier in the lesson, the match at the segment start was still the strongest or within 15% |
| Segment end (ayah 3, 16 s) | Stopped at the end: -26.9 dBFS before, digital silence after |
| Rapid tap: ayah 2, then ayah 6 0.27 s later | Ayah 6 played |
| Force-stop and restart, still offline | Ayah 5 played from 41:50.92 (segment start 41:50.80); the same file was reused (same mtime) and no `.part` files were left |
| Original after the run | Unchanged |

A further offline walkthrough of the same install ([screenshots](evidence_2026-11-13/)):

- Go to page 300 opened Al-Kahf 18:54, the page start.
- Swipes worked; Index → At-Tawbah worked.
- Bookmarking 9:3 worked and it appears under Bookmarks.
- Settings changed: Arabic, light page, text size 30.
- After a force-stop and relaunch, all of these were kept, and the reader reopened at 9:2.

**Not tested on the device:** typing an Arabic search. adb can't type Arabic. Search is covered by widget tests and works offline by design (local data only).

## 9. Files changed

**Modified (31 files, not counting 19 regenerated goldens):**
- **Android:** `android/app/build.gradle.kts`, `MainActivity.kt`.
- **Page data:** `assets/quran/tanzil-uthmani-1.1/metadata.json` (pages added), `tool/quran/import_metadata.dart`.
- **Quran:** `lib/app/router.dart`, `reading_state.dart`, `quran_metadata.dart`, `quran_metadata_repository.dart`, `quran_reader_screen.dart`, `reading_controls.dart`, `surah_text_view.dart`.
- **Audio and About:** `about_screen.dart`, `fatiha_sync.dart`, `recording_repository.dart`, `recording.dart`, `tafsir_player_bar.dart`.
- **l10n:** both ARB files and the generated localizations.
- **Docs:** `PHASE_0_DECISIONS.md` (C-29, C-30, P-24), `QURAN_AND_AUDIO_ACCURACY.md`, `review/AL_FATIHA_TAFSIR_REVIEW.md`.
- **Tests:** `quran_reader_test`, `reader_features_test`, `settings_test`, the golden test, `all_surahs_numbering_test`, `rendered_numbering.dart`, `synthetic_quran_metadata.dart`.

**New:**
- **App:** `lib/core/build_flags.dart`, `widgets/mushaf_page.dart`.
- **Tests:** `test/features/mushaf_reader_test.dart`, `test/quran/all_pages_test.dart`, `mushaf_pages_test.dart`, `qf_page_numbers.json`, `test/tafsir_audio/recording_repository_test.dart`, and 7 page goldens.
- **Tools:** `tool/build_testing_apk.sh`, `tool/device/fresh_install_check.sh`, `verify_heard_segments.py`, `android_ui.py`.
- **Reports:** these reports and the evidence folder.

## 10. Tests

- `dart format --set-exit-if-changed .`: 0 files changed.
- `flutter analyze`: no issues.
- `flutter test`: **258 passed, 0 failed** (211 before; nothing removed).
- Existing whole-surah tests now pin that layout explicitly. The fail-closed test was split per layout.

## 11. Device evidence

Section 8. Everything ran on the Android emulator (API 37, x86_64). **No physical device was available**, so real-phone audio routing, other vendors' storage behaviour and arm64 performance are untested.

The audio check captured only the emulator's own output stream through a private PipeWire sink; the links were checked before recording, and no microphone was used.

## 12–14. APKs

| APK | Type | Size | Path |
|---|---|---|---|
| **Testing, with R3** | Debug build, **debug-signed, NOT for distribution**; all 3 ABIs | 220,131,732 bytes (incremental debug packaging; the entries total 189 MB). SHA-256 `bcbcb81c…20081e` | `build/app/outputs/flutter-apk/sheekhcali-1.0.0-debug-TESTING-with-R3-NOT-FOR-DISTRIBUTION.apk` |
| Default (no recording) | Debug, debug-signed | 220,133,018 bytes | `build/app/outputs/flutter-apk/app-debug.apk` |

- Package ID `com.example.sheekhcali` is unchanged in both.
- Logo, the Quran and metadata assets and the fonts are included.
- **No release APK was built:** there is no production keystore and no distribution right for R3.

## 15. Remaining blockers

| Blocker | Owner action |
|---|---|
| R3 distribution rights (C-26/C-29: testing only) | Confirm rights before any public build may contain it |
| Tafsir segments: 0 of 7 reviewed | Review in `docs/review/fatiha_review.html`, then import with `--sign-off`. Until then only labelled unreviewed candidates play, in testing builds |
| Production signing (release uses the debug key) | Create a keystore and `key.properties`. Not invented here |
| Printed Mushaf line layout (P-24) | KFGQPC permission or Quran Foundation font terms |
| Reader's on-device check of the text (P-07, P-26) | Name the qualified reader |
| iOS | Not built or tested (no Mac). The unpack channel exists on Android only, so an iOS testing build would report "not installed" |
| Cold start (UX) | The first tap after each launch takes 7–10 s to be heard on the emulator: the player builds an exact seek index for this variable-bitrate file, and debug builds are slower. The player shows "loading" meanwhile. Later taps were heard from 1.4–2.5 s into their segment 2 s after the tap, so they start within about half a second. A constant-bitrate playback copy (QURAN_AND_AUDIO_ACCURACY §5.2) would remove this, but it needs an approved derived file |

## 16. Production readiness

- **Quran reader: ready for owner review.**
  - Verified text and verified page boundaries, every page checked.
  - Works fully offline.
  - Not publishable until the reader's check (P-07) and signing are done.
- **Offline Sheikh audio: works in the testing APK after a plain install, with no network and no developer step.** Proven on a wiped emulator by audio capture. The testing APK is **not** a release and must not be shared.
- **Public release: not ready.** It is blocked by signing, R3 distribution rights and Tafsir review.

Nothing was committed, pushed or merged.
