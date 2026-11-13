# Al-Fatiha review guide (owner)

You are the reviewer for Al-Fatiha (decision C-27). The app highlights an ayah while the Sheikh's recording plays **only** for time spans you have checked and signed off. This guide covers your two checks: the Quran text on a phone, and the ayah timestamps in the recording.

Nothing here changes the original recording. It is only read.

## Part 1: Check the Quran text on a phone (about 10 minutes)

The text is Tanzil Uthmani 1.1, imported byte for byte. All 6,236 ayahs of the source file were validated, and all 7 ayahs match an independent source (the Quran Foundation text) letter for letter. Your check is about **what the phone shows**: the font and the marks.

1. Open the app → Quran. Al-Fatiha appears.
2. Read all seven ayahs against a printed Madinah mushaf. Check:
   - every letter and every mark (fatha, kasra, damma, sukun, shadda, tanwin, maddah ـٓ, the dagger alef ـٰ, the alef wasla ٱ);
   - that no mark collides with another or is clipped at the line edges;
   - the ayah numbers ١ to ٧ come after the right ayahs (the basmala is ayah 1, as in the source);
   - the light and dark reading themes (⋮ → Light mode);
   - the app in English and in Arabic (Settings → Language). The Quran text must be identical in both.
3. If everything is right, record your sign-off (from the repo folder):
   ```
   dart run tool/quran/sign_off_text.dart --surah 1 --reviewer "Your Full Name"
   ```
   The reader then shows "Checked by Your Full Name · date" instead of "Reviewer check pending".
4. If anything is wrong, **don't sign off**. Note the ayah and what you saw; it is probably a font issue, and the text itself will not be edited (Tanzil's terms forbid changes).

## Part 2: Confirm where the Sheikh explains each ayah (about 20–30 minutes)

Only segments you approve count as the Sheikh's verified explanation. Until then, in **debug/testing builds** (the only builds that can play this recording), tapping an ayah plays its AI-assisted **candidate** segment, so you can hear it at once. The player line turns amber and reads, for example, "Unreviewed AI candidate · Ayah 2 · 33:00–37:47 · low confidence · not verified". Playback stops at the end of the segment. A segment you approve replaces the candidate for that ayah. With review mode off, as in production, an ayah without an approved segment says "Ayah N has no reviewed explanation yet." and plays nothing (decision P-25).

**Quickest review: in the app.** Install the recording (see "Checking it in the app" below), open Al-Fatiha, and tap each ayah. If you hear the Sheikh explaining that ayah from about the start, note "OK". If not, note what you hear and where. Then confirm the exact boundaries in the review page below, which can play exact segments and adjust them.

To spare you the 48-minute search, the whole recording was analysed in advance (machine transcript plus listening for structure). The result is a list of **candidate** segments in `docs/review/candidates/r3-candidates.json`, each with a proposed start and end, a confidence level and the evidence behind it. **None of them is verified.** Your listening decides.

### Steps

1. Open `docs/review/fatiha_review.html` in Chrome or Firefox (double-click it; it works offline).
2. In box 1, **Original recording**, pick `shiiq_mp3/003-الفاتحة 1-آخرها.mp3`. The page checks its SHA-256 and refuses any other file. Nothing is uploaded, and the file is only read.
3. Type your full name in box 2, **Reviewer**.
4. Explanation candidates come first, in ayah order. For each one:
   - Read the ayah (Arabic) and the evidence.
   - Press **▶ Play segment** to hear exactly that stretch of the original recording. Use **▶ First 15 s** and **▶ Last 15 s** to check the boundaries.
   - If the boundaries are off, adjust Start or End with −5 / −1 / +1 / +5 seconds, or play and press **= now** at the right moment.
   - If the Sheikh explains several ayahs together, change *Ayahs* to, for example, `2-4`. One segment can cover several ayahs.
   - Choose **Approve** only if you heard him explaining that ayah. Otherwise choose **Reject**, or leave it **Undecided**.
5. The coverage chips at the top show which ayahs have an approved explanation. Ayahs you leave uncovered keep saying "no reviewed explanation", which is the honest answer.
6. In box 3, click **Download approved labels**. Your browser saves `r3-labels-approved.txt`, usually in Downloads. Optionally, **Download full review record (JSON)** keeps a copy of all your decisions. Your progress is also kept in the browser, so you can stop and continue later.
7. In the repo folder, run the command the page shows (adjust the path to where the file was saved):
   ```
   dart run tool/alignment/import_labels.dart --labels ~/Downloads/r3-labels-approved.txt --recording "shiiq_mp3/003-الفاتحة 1-آخرها.mp3" --sign-off --reviewer "Your Full Name"
   ```
   It re-checks the recording's SHA-256, overlaps, the end of the recording and ayah numbers 1–7, then writes your approved spans, with your name and the date, to `assets/content/alignments/al-fatiha-tafsir-r3.json`. Run it without `--sign-off` first if you only want the check.
8. Rebuild the app. The amber "Unreviewed" label disappears for the ayahs you approved. For each one:
   - tapping it plays **its explanation** from the start you set (never the opening recitation);
   - if the Sheikh explains it both alone and together with other ayahs, the dedicated segment wins;
   - tapping another ayah while audio plays switches straight to that ayah's segment;
   - the ayah is highlighted, and the player line shows the ayah number, "explaining" and the segment's time range.

### Alternative: Audacity

If you prefer Audacity, label time ranges as `explanation 3`, `explanation 2-4`, `reading 3`, `intro` or `qa` (spans must not overlap). Then export the labels and import them with the same command. `docs/review/drafts/r3-draft-labels.txt` holds the old machine hints. These are quotations only, often wrong, and marked `DRAFT … ?`, so they are never signed off.

### Checking it in the app (testing only)

The recording is approved for testing only (C-26), so it is **not inside the app**. For a debug build on an emulator or phone connected with adb, from the repo folder:

```
tool/device/install_r3.sh
```

It checks the file's SHA-256 on this computer, installs the debug app if needed, copies the recording into the app's private storage and checks the copy's SHA-256 on the device. Raise the media volume: the emulator starts at 5 of 15, which is faint.

The app checks the file's SHA-256 before playing. A different or damaged file is refused. Release builds never play it, and **the web build cannot play it** (it shows "The Sheikh's recording plays only in the Android and iOS app…"): the testing-only file is never put into a web bundle.

On the emulator, the first tap takes a few seconds (about 5 s measured) because the player indexes the variable-bitrate file up to that point, which makes the seek exact. Later taps start in under a second.

The on-device check of all seven ayahs, including that the audio is really heard (Linux with PipeWire and an Android emulator):

```
PYTHON=/path/to/python-with-numpy-and-miniaudio tool/device/fatiha_audio_check.sh
```

It records only the emulator's audio output, never a microphone, and fails if any tap is silent or comes from the wrong place in the recording. `flutter test` uninstalls the app afterwards, so run `tool/device/install_r3.sh` again before using the app.

## What the app guarantees

- Only spans that are `verified`, signed (reviewer and date), valid, bound to this exact recording, **and** whose ayah texts are unchanged ever highlight. Everything else highlights nothing.
- The highlight is computed from the playback position alone, so seeking anywhere shows exactly what playing to that point would show.
- Seeking in this variable-bitrate MP3 uses ExoPlayer's index seeking, so timestamps land where you marked them (measured on the emulator: within 0.5 s of the requested point).
- A tap uses an **explanation** segment only, never a recitation span: your approved one if there is one, otherwise (debug builds only) the candidate, labelled unreviewed. It stops at the segment's end.
