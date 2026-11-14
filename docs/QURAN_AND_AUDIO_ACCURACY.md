# Quran and audio accuracy

Phase 0, 2026-11-13. This document defines how Quran text, Tafsir, Sheikh recordings, transcripts and sync mappings are sourced, stored and verified before anything is shown to users as authentic. It is a specification only; nothing has been imported.

**Goal:** the highest accuracy that can be **verified**, with evidence for every claim. It never claims perfection without proof.

**Evidence labels:** VERIFIED · PARTIALLY VERIFIED · NOT FOUND · NOT TESTED · BLOCKED.

---

## 1. Content layers are kept separate

Each layer is its own entity, with its own source, version, verification status and attribution. No layer is ever merged into another's text field.

| # | Layer | Authority | Who can change it |
|---|---|---|---|
| 1 | Quran text | The chosen verified source, stored byte for byte | Nobody. Only a new verified source version can replace it, through review |
| 2 | Mushaf layout (pages, lines, juz, hizb) | The same edition as the mushaf font | Nobody (data import only) |
| 3 | Translation of meanings | A named, licensed translation | Nobody (data import only) |
| 4 | Original Tafsir text | A named printed edition supplied by the owner | Editors can correct OCR mistakes, with review |
| 5 | Original book text | A named edition supplied by the owner | Same as Tafsir |
| 6 | Sheikh's original recording | The original file, immutable, identified by SHA-256 | Nobody |
| 7 | Playback copy of a recording | Derived from 6; must match its timeline | Generated, then checked |
| 8 | Draft transcript | AI-generated, labelled **Draft (AI)** | Editors |
| 9 | Verified transcript | Draft reviewed by a qualified person | Reviewer sign-off |
| 10 | Passage mapping (alignment) | Reviewed by a person; bound to exact versions of 4–7 | Aligner, then reviewer |
| 11 | Editorial notes | Written by named editors and labelled as notes | Editors |

The app always shows which layer the user is reading. For example, the Sheikh's explanation is never styled like Tafsir text, and a Draft (AI) transcript is never shown without its label.

---

## 2. Quran text source

### 2.1 Candidates, checked 2026-11-13

| Source | Script | Terms (as read on the source's own page) | Offline use | Status |
|---|---|---|---|---|
| **Tanzil** (tanzil.net) | Uthmani and Uthmani Minimal (based on the Medina Mushaf); Simple variants | "Permission is granted to copy and distribute verbatim copies… changing the text is not allowed… source (Tanzil Project) is clearly indicated", plus a link back to tanzil.net. **Text version 1.1, February 2021** | Allowed (verbatim, with attribution) | VERIFIED from tanzil.net/download on 2026-11-13. The separate licence page is empty |
| **Quran Foundation** Content APIs | Several Uthmani encodings, mushaf data, translations, Tafsir, audio | Developer Terms: QF content may not be cached for **more than 1 week**, unless it comes through the **Content Sync** APIs. Fonts and mushaf images may be bundled if you keep an active Developer Console account and credit Quran Foundation; they "may be distributed only as an integrated part of the Application" | Only through Content Sync, under its conditions | PARTIALLY VERIFIED. The terms page is dated 2026-10-11; read through search excerpts and the fonts page |
| **KFGQPC** (King Fahd Glorious Quran Printing Complex) | The official Madinah mushaf fonts and text | The font licence found says the fonts are KFGQPC property and may not be reproduced or modified without written approval. The official "Usage Rights" clause couldn't be retrieved | **Unclear** | BLOCKED until the Complex's official terms are read or written permission is obtained |
| AlQuran.cloud | Mirrors Tanzil text | API terms not reviewed | Not reviewed | NOT TESTED |

### 2.2 Decision: approved (C-25, 2026-11-13)

**Tanzil Uthmani 1.1 is approved.** Al-Fatiha has been imported by `tool/quran/import_tanzil.dart`:

| Item | Result |
|---|---|
| Source file | `quran-uthmani.txt` from tanzil.net, header "Tanzil Quran Text (Uthmani, Version 1.1)", CC BY 3.0 with the verbatim-only terms; SHA-256 `bf4f57b9…312c8`; retrieved 2026-11-13 |
| Metadata | `quran-data.xml` version 1.0; SHA-256 `8867c1d8…5c7a` |
| Whole-file validation | 6,236 ayahs, contiguous; every per-surah count equals the metadata (114 suras); no control characters, BOM or CR |
| Numbering convention (from the file) | Hafs, Kufan count. **Al-Fatiha has 7 ayahs and the basmala is ayah 1.** Tanzil prefixes the basmala to the first ayah of surahs 2–114 (for example 2:1), except At-Tawbah (9) |
| **Basmala display rule** (adopted 2026-11-13, enforced by `tool/quran/import_tanzil.dart` and `test/quran/full_quran_test.dart`) | The stored ayah text stays verbatim and hashed. For surahs 2–114 except 9, the first four words of ayah 1 must equal Al-Fatiha's basmala letter for letter. They are shown as an **unnumbered heading** with the surah's own bytes: 95 and 97 read "بِّسْمِ", with a shadda, and that is shown as is. Ayah 1 is then shown and copied as the exact remainder after that prefix and one space. At-Tawbah must have no basmala. Any deviation fails the import. |
| Independent cross-check | Quran Foundation Content API v4 `text_uthmani` (KFGQPC-based): **all 7 ayahs match letter for letter**, and also mark for mark once a tatweel encoding difference is ignored. Only the comparison result is stored, per QF caching terms |
| Stored | `assets/quran/tanzil-uthmani-1.1/surah-001.json` (verbatim text, per-ayah SHA-256, licence block verbatim) + independent manifest `test/quran/surah-001.manifest.json` |
| Font | Amiri 1.002 (SIL OFL) covers all 32 code points used (tested). KFGQPC page fonts stay blocked (P-24) |
| Reviewer on-device check | **Pending** (owner, C-27); see `docs/review/AL_FATIHA_TAFSIR_REVIEW.md` |

Original recommendation, kept for the record:

- **Primary text: Tanzil Uthmani 1.1**, stored verbatim with attribution and a link back, as Tanzil's terms require.
- **Independent cross-check:** a second source, either KFGQPC's own text or Quran Foundation's Uthmani text under its terms, used **only for verification at build time**, never shipped.
- **Mushaf page mode** needs page and line data **from the same edition as the font**. That means KFGQPC/QPC page fonts and layout data, either through Quran Foundation (bundling permitted under conditions) or through KFGQPC's permission. The printed line layout stays **BLOCKED** until one of these is cleared. Since C-30 the reader shows the Madinah Mushaf **page boundaries** (604 pages, copied from the approved Tanzil metadata and cross-checked ayah by ayah against Quran Foundation) with its own reflowing text, and says so in the source dialog and the reading controls. Continuous (reflowing) mode only needs the text and a licensed font.

### 2.3 Provenance record, stored for each imported source

`sourceName`, `sourceUrl`, `version`, `retrievedAt`, `licenceText` (verbatim), `fileSha256`, `encodingNotes`, `importedBy`, `reviewedBy`, `reviewedAt`, `status`.

---

## 3. Quran verification strategy

### 3.1 Text integrity

1. **Byte preservation.** Ayah text is stored exactly as the source supplies it. **Unicode normalisation (NFC or NFKC) is never applied**, because NFC reorders combining marks such as shadda and fatha. Search uses a separate derived column, with an offset map back to the original.
2. **Checksum manifest.** At import, a manifest records the SHA-256 of every ayah and of the whole text. The manifest is committed. An automated test confirms that the bundled database matches it exactly.
3. **Round-trip test.** Reading from the database and serialising back reproduces the original source file byte for byte.
4. **Display path test.** A widget test checks that the string passed to the text renderer equals the stored string, so nothing trims, replaces or reorders it on the way to the screen.

### 3.2 Structural invariants (automated, against the source's own metadata, then cross-checked)

| Invariant | Expected value (Hafs, Kufan count) | Verified how |
|---|---|---|
| Surah count | 114 | Source metadata + second source |
| Total ayahs | 6,236 | Same |
| Ayahs per surah | 114-row table from the source | Both sources must agree on every row |
| Surah order and names (Arabic and transliterated) | From the source | Both sources must agree |
| Al-Fatiha | 7 ayahs, with the basmala as ayah 1 | Checked explicitly |
| Basmala | Not numbered in other surahs; absent from At-Tawbah (9) | Checked explicitly |
| Juz / hizb / quarters | 30 / 60 / 240 boundaries, as ayah references | Source metadata + second source |
| Sajdah positions | As the source lists them | Source metadata + second source |
| Mushaf pages | 604 pages in the Madinah edition, as ayah ranges | Boundaries copied from the approved Tanzil metadata (never computed by us) and the page of all 6,236 ayahs equal to Quran Foundation's `page_number` (C-30, `test/quran/mushaf_pages_test.dart`, every page rendered in `all_pages_test.dart`). Line layout only from the font edition's own data (P-24) |

The "expected values" column states the generally accepted figures for the Hafs Madinah mushaf. The tests take their expected values from **the source data**, and a mismatch between sources fails the build. The figures are never typed in from memory.

### 3.3 Cross-source comparison

Two sources often encode the same Uthmani text with different Unicode sequences (for example, small high marks or the form of the superscript alef). The comparison therefore runs in two passes:

1. **Letter skeleton** (letters only, every mark removed). It must match exactly for all 6,236 ayahs.
2. **Diacritic and mark comparison** through an explicit, reviewed mapping table between the two encodings. Any remaining difference goes into a report for a qualified reviewer. Nothing is "fixed" automatically.

### 3.4 Rendering verification

- **Glyph coverage:** an automated test checks that the chosen Quran font has a glyph for every code point in the text.
- **Device check by a qualified reader** (hafiz or teacher) of a fixed list of pages, on a real Android phone, in both UI languages and at the smallest and largest reading sizes. The list includes Al-Fatiha, the start of Al-Baqarah, and places with rare Hafs marks that the reviewer confirms. Commonly cited examples are the sakt marks (Al-Kahf 1–2, Ya-Sin 52, Al-Qiyamah 27, Al-Mutaffifin 14), imalah in Hud 41, ishmam in Yusuf 11 and tas-hil in Fussilat 44. Those locations must be confirmed by the reviewer, not taken from this document.
- The reviewer's name, date, device and result are recorded in `docs/QURAN_VERIFICATION_LOG.md`, created in Phase 6.

### 3.5 Regression

- The checksum and invariant tests run in CI on every change.
- Changing the Quran source version needs a new import, the full test run, a new cross-check report and a reviewer's sign-off.
- If verification fails, the text is marked **Unverified** and the Quran reader shows a notice instead of the text. **Unverified Quran text is never shown as authentic.**

### 3.6 Other date and devotional content on the Home screen

- **Hijri date** (reference screenshot 01: "2 Jumada al-Thani 1448 AH" on 12 November 2026). The calculation method must be named (for example Umm al-Qura, or astronomical), and users need a **±1 or ±2 day adjustment**, because local moon sighting differs. The default method is decision P-11.
- **Dhikr of the Day.** Each dhikr needs its Arabic text from a verified source, a named source reference (book and number), and a translation from a named translator. The translation in screenshot 01 contains explanatory brackets. Is it an editorial translation, and whose? (Pending, P-12.) No dhikr is shown without its reference.

---

## 4. Translations and Tafsir

- **Translation of meanings** (English): a named translation whose licence allows offline distribution. It is kept as a separate entity and labelled "Translation of meanings", never "Quran". Candidates are checked in Phase 6.
- **Tafsir text:** only from editions the owner supplies **with rights**, or licensed sources whose terms allow offline storage. (Quran Foundation's Tafsir is usable offline only through Content Sync; see §2.1.) Each Tafsir passage records its edition, volume, page and **ayah range**. A passage covering several ayahs is stored as a range, never split by guesswork.
- **OCR'd Tafsir** keeps the original page image. Its text stays **Needs verification** until a reviewer compares it with the page. Unverified OCR text is shown only with a label, next to the page image.
- **No AI-generated Tafsir, summaries or explanations**, at any stage.

---

## 5. Sheikh recordings

1. **The original is immutable.** Store the file exactly as received, with SHA-256, byte size, original filename, duration (measured with ffprobe), source and rights reference. Exact duplicates are detected by hash; similarly named files are not assumed to be duplicates.
2. **Playback copy.** AAC in M4A at a constant bit rate, made from the original. Acceptance: duration within **50 ms** of the original and starting offset within **10 ms**. These targets are carried over from the reference project and still need confirming on a device. The sync timestamps always refer to the **original's** timeline.
3. **Variable-bitrate source.** R3 is a variable-bitrate MP3 (32–40 kbps) with only a Xing table of contents. Many Android players estimate seek positions in such files from that coarse table, so a seek can land seconds away from the timestamp. Sync timestamps are therefore defined on the original's decoded sample timeline, and playback uses the constant-bitrate copy from step 2 (or an MP3 with an exact seek index). A device test confirms this.
4. **Seek accuracy test.** On a real Android device, seek to 20 or more known timestamps and measure the error. The required tolerance is set before Phase 4 is accepted; the proposed limit is ≤ 150 ms at the 95th percentile.
5. **Rights per recording:** may it be streamed publicly, downloaded or played offline?

---

## 6. Transcripts

| Status | Meaning | Shown to users? |
|---|---|---|
| Missing | No transcript | — |
| Draft (AI) | Speech-to-text output; language tagged per segment (Somali, Arabic, English) | Only if the owner allows it, always labelled "Automatic transcript, not reviewed" |
| Needs verification | An editor has corrected it | No |
| Verified | A qualified reviewer has compared it with the audio and signed off | Yes |
| Rejected | Failed review | No |

- The speech-to-text tool (Whisper large-v3 or WhisperX, or another) is **chosen by measuring accuracy on the Sheikh's actual recordings**: word error rate on a hand-transcribed 5-minute sample in each language the Sheikh uses. The results are recorded before adoption.
- Arabic matn that the Sheikh reads aloud is **never replaced** by the ASR output. The transcript points to the book passage instead.
- Translating a transcript is out of scope. The interface languages are English and Arabic; the Sheikh's Somali speech is transcribed in Somali.

---

## 7. Passage mappings (audio ↔ text)

### 7.1 Model

- A **span** is `[startMs, endMs)` on the original recording's timeline, with a **kind**: `reading` (the Sheikh reads the text), `explanation`, `intro` or `qa`.
- Spans link to **targets** many-to-many. A target can be a book passage, a Tafsir passage, an ayah range, or a sentence inside a passage.
- A mapping is valid only for **one recording SHA-256 and one text revision per target**. If either changes, the affected spans become **stale** and are not highlighted until an aligner re-confirms them.
- **Gaps and unlinked spans highlight nothing.** Nothing is ever highlighted by interpolation or guesswork.

### 7.2 Workflow

1. **Machine assistance** (optional): forced alignment for `reading` spans only, where the text is read verbatim. It produces suggestions marked **Draft (machine)**.
2. **The aligner** marks `explanation`, `intro` and `qa` spans by hand while listening, and links them to targets.
3. **The validator** runs automatic checks. Errors block submission: overlapping spans of the same kind, spans past the end of the recording, links to missing or stale targets, `reading` or `explanation` spans with no target. Gaps of 1 s or more raise warnings.
4. **The reviewer** is a second qualified person, never the aligner. They listen to every span boundary and target, then approve or reject.
5. **Publish.** Only **Verified** mappings reach the reader.

### 7.3 Acceptance for each lesson

- 100% of spans reviewed, with the reviewer's name and date recorded.
- Device test: playback from the start, seeking to 10 random points, tapping 10 passages, pausing and resuming, airplane mode. The highlighted passage matches what the Sheikh is saying in every check.
- The validator reports no errors.

---

## 8. Surat Al-Fatiha: first audio and Tafsir experience

### 8.1 Target experience (Phase 0 spec §8)

Open Al-Fatiha → read the verified Arabic text → open the matching Tafsir → listen to the Sheikh's original explanation → the reader follows and highlights the passage being explained → pause, resume and seek → tap a passage to jump to its explanation, where a verified mapping exists.

### 8.2 Readiness, 2026-11-13

| Requirement | Status | Evidence |
|---|---|---|
| Verified Quran text for Al-Fatiha | **Imported and automatically verified** (C-25; §2.2). On-device reviewer check pending | `test/quran/al_fatiha_text_test.dart` |
| Mushaf page 1 layout | **BLOCKED** on the font and layout licence (§2.1) | — |
| Tafsir text for Al-Fatiha | **NOT FOUND.** Which Tafsir does the Sheikh teach from, and which edition? | `CONTENT_INVENTORY.md` |
| The Sheikh's Al-Fatiha recording | **FOUND, unconfirmed.** `shiiq_mp3/003-الفاتحة 1-آخرها.mp3.mpeg`: 48:32.0, SHA-256 `3300e364…`, ID3 artist "الشيخ علي نور". The link to Al-Fatiha rests on its filename and title; nobody has listened to it yet | `CONTENT_INVENTORY.md` R3 |
| Rights for the recording and the Tafsir | Recording: **shipped in every build** by the owner's decision C-31 (2026-11-14), byte-identical to the original. Tafsir text: not supplied | `docs/content/R3_RECORDING_REPORT.md` |
| A qualified reviewer for the mapping | **The owner** (C-27). Workflow ready; no spans reviewed yet | `docs/review/AL_FATIHA_TAFSIR_REVIEW.md` |
| Transcript | Machine draft only (C-28), evidence for the reviewer; not published | `docs/content/R3_RECORDING_REPORT.md` |

**Overall:** the text, player, synchronisation engine and review workflow are built and tested. **Live highlighting from R3 waits only on the owner's review** (no span is verified yet). The written Tafsir text (P-08) and distribution rights (P-22) are still outstanding. As the spec requires, only the architecture and interface specification are prepared (`DESIGN_SYSTEM_SPECIFICATION.md`, screen 12, and §7 above). **No demonstration with invented audio, Tafsir or timestamps will be built.**

### 8.3 Steps once the materials arrive

1. Register R3 (§5). Hash and duration are already recorded; ffprobe should confirm the duration once installed, and the rights are still needed. **A qualified listener first confirms that it really is the Sheikh teaching Al-Fatiha, and from which Tafsir.**
2. Import the Al-Fatiha ayahs from the approved source and pass §3.
3. Import the Tafsir pages: page images plus text, with OCR review if needed (§4). Record the edition and page numbers.
4. Split the Tafsir into passages with ayah ranges; a reviewer confirms the split.
5. Draft transcript (§6), labelled as AI.
6. Listen and mark spans (§7.2). The expected pattern is that the Sheikh recites or reads, then explains, but this is checked on the recording, not assumed.
7. Validator → reviewer → publish to a **test** channel only.
8. Device acceptance (§7.3), online and in airplane mode.
9. Record the evidence in `docs/FATIHA_VALIDATION_REPORT.md`.

---

## 9. Who verifies

Each role is recorded by name in the CMS. The aligner and reviewer of the same item must be different people.

| Content | Verifier needed | Named? |
|---|---|---|
| Quran text and rendering | A hafiz or qualified Quran teacher | No (P-07) |
| Tafsir and book OCR | An Arabic-literate editor familiar with the text | No |
| Somali transcripts | A fluent Somali speaker familiar with the Sheikh's lessons | No |
| Mappings | A reviewer other than the aligner | No |
| Adhkar references | A person qualified in hadith sources | No |
