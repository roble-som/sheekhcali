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

## Part 2: Mark which ayah the Sheikh is explaining, and when

### What you need

- The original recording: `shiiq_mp3/003-الفاتحة 1-آخرها.mp3` (SHA-256 `3300e364…`, 48:32).
- **Audacity** (free, audacityteam.org) to see the waveform and mark time ranges.
- Optional head start: `docs/review/drafts/r3-draft-labels.txt`. These are machine guesses of where the Sheikh **quotes** each ayah, made by a local speech-to-text model. They are labelled `DRAFT … ?`, are often imprecise, and only mark quotations, not explanations.

### Steps

1. Open the recording in Audacity (File → Open). **Never save or export the audio.** We only need the labels.
2. Optional: File → Import → Labels… → choose the draft labels file. They appear as a label track.
3. Listen. For each part of the lesson, select the time range on the waveform and add a label (Ctrl+B). Type one of these:

   | Label | Meaning | Highlights |
   |---|---|---|
   | `reading 3` | The Sheikh reads/recites ayah 3 | Ayah 3, full highlight |
   | `explanation 3` | He explains ayah 3 | Ayah 3, lighter highlight with a gold mark |
   | `explanation 3-4` or `explanation 3,4` | He explains ayahs 3 and 4 together | Both |
   | `intro` | Opening, du'a, anything not tied to an ayah | Nothing |
   | `qa` | Questions and answers | Nothing |

   Rules: spans must not overlap; a gap between spans highlights nothing (that's fine). For each draft label, either delete it or retype it without `DRAFT` and `?` once you've confirmed it by listening. Anything still marked `DRAFT` is never signed off.
4. File → Export → Export Labels… → save as, for example, `r3-labels.txt`.
5. Import your labels. First run without signing, to check them:
   ```
   dart run tool/alignment/import_labels.dart --labels r3-labels.txt --recording "shiiq_mp3/003-الفاتحة 1-آخرها.mp3"
   ```
   It refuses to write anything if the recording isn't the original (SHA-256), if spans overlap or go past the end, or if an ayah number is outside 1–7.
6. When you are satisfied, sign off:
   ```
   dart run tool/alignment/import_labels.dart --labels r3-labels.txt --recording "shiiq_mp3/003-الفاتحة 1-آخرها.mp3" --sign-off --reviewer "Your Full Name"
   ```
   Every non-draft span is stored as verified, with your name and today's date, in `assets/content/alignments/al-fatiha-tafsir-r3.json`.
7. Rebuild the app. While the recording plays, each ayah lights up during your signed-off spans. Tapping a mapped ayah jumps to its first `reading` span (or its first span if there is no reading span).

### Checking it in the app (testing only)

The recording is approved for testing only (C-26), so it is **not inside the app**. For a debug build on an emulator or phone connected with adb:

```
adb push "shiiq_mp3/003-الفاتحة 1-آخرها.mp3" /data/local/tmp/r3.mp3
adb shell run-as com.example.sheekhcali mkdir -p files/dev-media
adb shell run-as com.example.sheekhcali cp /data/local/tmp/r3.mp3 files/dev-media/3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f.mp3
adb shell rm /data/local/tmp/r3.mp3
```

The app checks the file's SHA-256 before playing. A different or damaged file is refused. Release builds never play it.

## What the app guarantees

- Only spans that are `verified`, signed (reviewer and date), valid, bound to this exact recording, **and** whose ayah texts are unchanged ever highlight. Everything else highlights nothing.
- The highlight is computed from the playback position alone, so seeking anywhere shows exactly what playing to that point would show.
- Seeking in this variable-bitrate MP3 uses ExoPlayer's index seeking, so timestamps land where you marked them.
