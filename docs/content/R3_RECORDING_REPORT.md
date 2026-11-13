# Recording R3: identity, content and rights

Inspected 2026-11-13. **Evidence labels:** VERIFIED · PARTIALLY VERIFIED · NOT TESTED · OWNER-STATED.

## Identity (file facts)

| Fact | Value | Label |
|---|---|---|
| Current path | `shiiq_mp3/003-الفاتحة 1-آخرها.mp3` (renamed by the owner from `….mp3.mpeg` at 12:33 on 2026-11-13; bytes unchanged) | VERIFIED |
| SHA-256 | `3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f` (same before and after the rename, and after every analysis) | VERIFIED |
| Size | 12,587,299 bytes | VERIFIED |
| Format | MPEG-1 Layer III, 44.1 kHz, joint stereo, **variable bitrate** (32/40 kbps) with a Xing header | VERIFIED (every frame parsed) |
| Duration | 2,912.0 s = **48:32.0** (the Xing header and a full frame count agree) | VERIFIED |
| ID3 title | `003-الفاتحة 1-آخرها` | VERIFIED as a tag value; not proof of content |
| ID3 artist | `الشيخ علي نور` | VERIFIED as a tag value; the official Arabic name is still pending (P-19) |

The app identifies the recording by its SHA-256, never by its filename. Every alignment is bound to this hash.

## Content

| Question | Answer | Label |
|---|---|---|
| Is it the Sheikh's Tafsir of Al-Fatiha? | The owner says yes (C-26) | OWNER-STATED |
| Speaker | Sheikh Calinuur, per the owner; the ID3 artist is "الشيخ علي نور" | OWNER-STATED / tag |
| Tafsir or recitation? | A lesson: the draft transcript (below) shows an Arabic opening, a recitation of Al-Fatiha, and then long stretches that are not Arabic (very likely Somali explanation) | PARTIALLY VERIFIED (machine draft) |
| Which ayah is explained when | **Unknown until the owner's review** (C-27) | NOT VERIFIED |
| Which written Tafsir the lesson follows | Unknown (P-08) | NOT VERIFIED |

### Machine draft transcript (C-28): evidence only

whisper.cpp v1.9.5 (`ggml-small`, run locally; the audio never left this machine), Arabic mode. **Not reviewed, not published, not used for highlighting.**

First minute (draft):

| Draft time | What the draft shows |
|---|---|
| 0:00–0:16 | Arabic opening: isti'adha, basmala, hamdala, salawat on the Prophet ﷺ |
| 0:21–0:57 | A recitation of the whole of Al-Fatiha in order (the draft tool matches 0:29–0:57 to ayahs 2→7 one by one) |
| 0:59 | The basmala again, apparently starting the lesson |

After that, the Arabic-mode draft turns into meaningless Arabic-looking text: the expected sign of non-Arabic (very likely Somali) speech. Whisper's Somali support is weak, so the draft is useful only for locating **Arabic quotations** of the ayahs. Those become `DRAFT reading n?` hints in `docs/review/drafts/r3-draft-labels.txt` for the owner (see the review guide).

### Full draft pass (whole recording)

whisper.cpp v1.9.5 (release ≥ 14 days old), `ggml-small` (SHA-256 `1be3a9b2…`), Arabic mode, no temperature fallback, 48:32 of audio in 82 minutes on this machine. `tool/alignment/asr_draft_labels.dart` turned it into **71 draft label lines** (`DRAFT reading n?`; 101 ayah candidates in total, since some segments match several ayahs) in `docs/review/drafts/r3-draft-labels.txt` (a segment is matched when at least 60% of an ayah's words appear in it, after removing marks).

What the draft suggests (**machine evidence only; the owner's listening decides**):

| Ayah | Candidate segments | Notes |
|---|---|---|
| 1 | 26 | Many are the basmala said at section openings, not necessarily ayah 1 being explained |
| 2 | 10 | Opening recitation (0:29); later around 13:35, 23:54, 27:00 and 37:28–38:55 |
| 3 | 32 | Shares "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ" with ayah 1: most are ambiguous with it |
| 4 | 24 | Common words: likely many false positives |
| 5 | 5 | Opening recitation (0:38), then a cluster at **42:01–45:33**: probably where ayah 5 is discussed |
| 6 | 2 | Opening recitation (0:43) and 25:36 |
| 7 | 2 | Opening recitation (0:47) and 25:28 |

Limits: Whisper's Somali is weak, so explanation passages come out as meaningless Arabic-looking text, with occasional repetition loops (one long "ههه…" run around 21–22 min). The draft can only locate Arabic quotations. It cannot tell which ayah the Sheikh is explaining in Somali; only the reviewer can.

The draft transcript itself stays outside the repository (`scratchpad`); only the hints file is kept, for the reviewer.

## Rights

| Question | Answer | Label |
|---|---|---|
| Use in development and emulator testing | Allowed | OWNER-STATED (C-26) |
| Bundling in the app, streaming, offline download | **Not allowed yet** | OWNER-STATED (C-26) |
| Written rights evidence | Not supplied (P-22) | — |

Consequences in the app: the recording is not in the APK. Debug builds play it only from a locally installed, hash-verified copy, and release builds can't play it at all (tested).
