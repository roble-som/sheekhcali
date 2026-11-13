# Content inventory

Phase 0 snapshot, inspected 2026-11-13. It lists every content item found on this machine for Sheekh Calinuur, and what is still missing. Nothing has been imported yet.

Revised 2026-11-13 for the owner's Phase 0 specification: the status vocabulary (C-11) and collection types (spec §9) were added. Pending items refer to [PHASE_0_DECISIONS.md](PHASE_0_DECISIONS.md).

**Evidence labels:** VERIFIED (directly confirmed), PARTIALLY VERIFIED (some evidence), NOT FOUND (looked for, not there), NOT TESTED, BLOCKED.

## Summary

| Content type | Found | Status |
|---|---|---|
| Design screenshots | 6 | VERIFIED. Copied to `docs/design/reference/`. The owner later added the same six files under `images/` (byte-identical, SHA-256 checked) |
| Logo | 0 source files | NOT FOUND. Only visible inside screenshots 01 and 02, at about 60 px. A source file (SVG or PNG of at least 1024 px) is needed |
| Islamic books (PDF, EPUB, TXT, scans) | 0 | NOT FOUND on this machine |
| Tafsir documents | 0 | NOT FOUND |
| Sheikh recordings | 3 unique | VERIFIED. Two Ajurrumiyyah (grammar) in `../quraan-app`, plus **one Al-Fatiha recording added to this repo at `shiiq_mp3/` on 2026-11-13** (R3) |
| Transcripts | 0 verified | One draft word-timing file per recording, marked "NEEDS REVIEW" (see below) |
| Supporting lesson images | 0 | NOT FOUND |
| Rights and distribution documents | 0 | NOT FOUND. Previous project D-03 records the owner's statement that rights exist for all titles; no document was reviewed |

**No book has been imported, published or made available offline.** The library can't be filled until the books are supplied.

## Where I looked

- `/home/roble/apps/sheekhcali` (this repo): a fresh `flutter create` template, plus the owner's `images/` (the six screenshots again) and `shiiq_mp3/` (R3), both added 2026-11-13.
- `/home/roble/apps/quraan-app`: the previous project for the same Sheikh ("Shiiq Calinuur", later "Diini"). All the recordings below come from here.
- `/home/roble/apps/roble`: a TypeScript monorepo with no Sheikh content (directory listing only; not inspected in depth).
- Not searched: the rest of the home directory, external drives and cloud storage. **If the books are somewhere else, tell me the path.**

## Sheikh recordings

| # | Title (from the filename) | Duration | Size | SHA-256 (first 16) | Locations | Book | Kind |
|---|---|---|---|---|---|---|---|
| R1 | متن الآجرومية 01 (Matn al-Ajurrumiyyah, lesson 1) | 49:10 according to the previous project's records (ffprobe isn't installed, so NOT TESTED here) | 8,730,268 B | `35d4929e9b3de285` | `quraan-app/Shiiqcalinuur/` (3 identical copies), `quraan-app/dev-media/matn_ajrumiyyah_01.mp3`, `quraan-app/apps/mobile/assets/audio/` | Al-Ajurrumiyyah (Ibn Ajurrum), Arabic grammar | Recorded as mostly sharh: Arabic matn read, then explained in Somali (previous project D-01; not checked against this recording) |
| R2 | إعراب الآجرومية 01 (I'rab al-Ajurrumiyyah, lesson 1) | 29:21 according to the previous project's records (NOT TESTED here) | 4,509,038 B | `f954682eded08465` | `quraan-app/Shiiqcalinuur/` (2 identical copies), `quraan-app/dev-media/irab_ajrumiyyah_01.mp3`, `quraan-app/apps/mobile/assets/audio/` | An i'rab (grammatical parsing) commentary on Al-Ajurrumiyyah; the exact edition is unknown | Unknown |

Duplicates: the files named `(1)` and `(2)` have the same byte size as their originals and are treated as copies. The previous project's manifest verified the hashes of the `dev-media` copies; byte equality of every copy is NOT TESTED.

R1 and R2 are not Tafsir.

### R3: Al-Fatiha (added 2026-11-13)

| Field | Value | Label |
|---|---|---|
| Path | `shiiq_mp3/003-الفاتحة 1-آخرها.mp3` (renamed by the owner from `….mp3.mpeg` on 2026-11-13; the SHA-256 is unchanged). Ignored by Git (`.gitignore`) | VERIFIED |
| Size | 12,587,299 bytes | VERIFIED |
| SHA-256 | `3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f` | VERIFIED |
| Format | MPEG-1 Layer III, 44.1 kHz, joint stereo, **variable bitrate** (73,268 frames at 32 kbps, 38,207 at 40 kbps, plus 1 header frame at 128 kbps). `file` reports "128 kbps", but that is only the first (Xing) frame | VERIFIED by parsing every frame (0 bytes unaccounted for) |
| Duration | **48:32.0** (2,912.0 s). The Xing header (111,475 frames) and a full frame count agree | VERIFIED |
| ID3 title (TIT2) | `003-الفاتحة 1-آخرها` ("003 – Al-Fatiha, ayah 1 to its end") | VERIFIED as a tag value; meaning PARTIALLY VERIFIED |
| ID3 artist (TPE1) | `الشيخ علي نور` | VERIFIED as a tag value. **Not proof** of the Sheikh's official Arabic name (P-19) |
| Content | Per the owner: Sheikh Calinuur's Tafsir of Al-Fatiha (C-26). A local machine draft shows an Arabic opening and a full recitation of Al-Fatiha in the first minute, then non-Arabic (very likely Somali) explanation. See `docs/content/R3_RECORDING_REPORT.md` | OWNER-STATED / PARTIALLY VERIFIED |
| Series | "003" suggests the third item of a series. Where are 001 and 002, and what's in them? | Pending |
| Rights | Testing only, not distribution (C-26); no written document yet (P-22) | OWNER-STATED |
| Linked text | None. The Tafsir edition is still needed (P-08) | NOT FOUND |

**The Al-Fatiha demonstration (Phase 4) is now blocked on the Tafsir text, rights and review, not on the recording.** Its link to Al-Fatiha rests on the filename and ID3 title only, until someone listens and confirms it.

## Draft timing files

| File | Covers | Status |
|---|---|---|
| `quraan-app/apps/mobile/assets/timing/ajrumiyyah-ch-01.json` | R1, word-level `start`/`end` | Its own note says: "NEEDS REVIEW — approximate timing from estimated alignment. Arabic text is from the standard Matn Al-Ajrumiyyah. Timing must be verified against the actual recording by a qualified person." **Not usable as a verified alignment.** The Arabic text in it isn't tied to a named printed edition |
| `quraan-app/apps/mobile/assets/timing/ajrumiyyah-ch-02.json` | R2 | Same status (NOT TESTED in detail) |

## Fonts found in the previous project

| Font | Licence | Notes |
|---|---|---|
| Amiri Regular and Bold | SIL OFL 1.1 (VERIFIED as Amiri's published licence; the file's embedded licence NOT TESTED) | Used for Arabic book text |
| Noto Naskh Arabic Regular | SIL OFL 1.1 | Arabic UI text |

Neither font reproduces the mushaf page in screenshot 03, which uses a Madinah-mushaf (KFGQPC-style) script. See `docs/design/DESIGN_GAPS.md`.

## Mapping between recordings and books

| Recording | Book | Evidence | Status |
|---|---|---|---|
| R1 | Matn al-Ajurrumiyyah | The filename only | PARTIALLY VERIFIED. The edition, page numbers and which chapter "01" covers are unknown |
| R2 | An i'rab commentary on Al-Ajurrumiyyah | The filename only | PARTIALLY VERIFIED. The commentary's author and edition are unknown |

No recording has been linked to any book page or paragraph.

## What I need from you

1. **All the Sheikh's completed books** (P-01): the folder path, or upload them. For each book, its PDF, EPUB or scans, plus any metadata you have (a spreadsheet is fine).
2. **The list of books the Sheikh has completed**, so the inventory can show what is still missing. Without it I can't confirm that "all" books have been imported.
3. **The full set of recordings**, organised however they are today. Folder names usually show the book and lesson.
4. **The Tafsir edition the Sheikh teaches Al-Fatiha from** (P-08). The recording (R3) has arrived; please confirm what it contains, and send recordings 001 and 002 if they exist.
5. **Rights** (P-22): written permission for each book and recording, or a statement of which ones may be distributed publicly, offline and with audio.
6. **The logo** as a source file (P-02).
7. Any existing **transcripts**.
8. **Dhikr texts with their references** (P-12), and **the About text** with the **Arabic spelling of the Sheikh's name** (P-19).

## Status vocabulary (C-11)

Every content item has exactly one of these statuses:

| Status | Meaning |
|---|---|
| Missing | Expected (for example on the owner's list of books) but not supplied |
| Imported | The original file is stored and hashed; nothing has been extracted yet |
| Processing | Extraction, OCR, transcription or alignment is running |
| Needs verification | Machine output or an editor's change is waiting for a qualified reviewer |
| Verified | A named reviewer has signed off |
| Approved for publication | Verified, **and** the rights record allows it |
| Published | Live in the app |
| Rejected | Failed review or rights; kept for the audit trail and not shown |

AI or OCR completing never moves an item past **Needs verification** on its own.

## Collection types (spec §9)

`sheikh_official` (the Sheikh Calinuur books) · `islamic_other` · `quran_related` · `tafsir` · `lesson_document`.
The English and Arabic display names of the Sheikh's collection are pending (P-19).

## Inventory template

Each supplied item gets one row. Unknown values are written as **"Not recorded"**, never guessed.

### Books and documents

| ID | Title (original) | Title (EN) | Title (AR) | Author | Collection type | Category | Language | Edition | Publisher | Volume(s) | Format | Pages | Source file + SHA-256 | Rights status | Content status | Content version | Offline | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (none supplied yet) | | | | | | | | | | | | | | | | | | |

### Recordings

| ID | Original filename | SHA-256 | Duration (ffprobe) | Language(s) | Book / volume / chapter / lesson | Evidence for that link | Rights | Transcript status | Mapping status | Content status |
|---|---|---|---|---|---|---|---|---|---|---|
| R1 | متن الآجرومية 01.mp3 | `35d4929e…` | 49:10 (from the reference project's records; NOT TESTED here) | ar + so (expected, not checked) | Al-Ajurrumiyyah / lesson 1 | Filename only | Owner's statement in the reference project; no document | Missing | Missing | Imported (in the reference project only) |
| R2 | إعراب الآجرومية 01.mp3 | `f954682e…` | 29:21 (as above) | Not checked | I'rab al-Ajurrumiyyah / lesson 1 | Filename only | As above | Missing | Missing | Imported (in the reference project only) |
| R3 | 003-الفاتحة 1-آخرها.mp3.mpeg | `3300e364…` | 48:32.0 (VERIFIED, frame count) | Not checked | Al-Fatiha, ayahs 1–7 (Tafsir edition unknown) | Filename + ID3 title only | NOT FOUND | Missing | Missing | Imported (file present in this repo; not registered) |
