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

## Candidate ayah-to-explanation map (AI-assisted, NOT VERIFIED)

Built on 2026-11-13 from the full draft transcript, the 71 draft labels (checked against each other rather than trusted; many are false matches of the basmala and of "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ") and the recording's structure. Stored in `docs/review/candidates/r3-candidates.json` with `status: candidate` and the evidence for each span. **Not used by the app.** The owner approves or corrects these in `docs/review/fatiha_review.html`.

| Part | Candidate time (m:ss.s) | Confidence | Evidence (machine transcript times) |
|---|---|---|---|
| Opening du'a | 0:00.0–0:25.0 | high | Arabic opening du'a: isti'adha, basmala, hamdala, salawat (0:00–0:16), then isti'adha before the recitation (0:21). |
| Recitation of ayahs 1–7 (Quran, **not Tafsir**; 7 separate spans) | 0:25.0–0:57.7 | high | Each ayah quoted in order |
| Lesson introduction | 0:57.7–11:07.9 | low | Basmala at 0:59, then mostly Somali speech the draft cannot read ("تفسير…" at 1:09). Probably the lesson introduction; content not identified. |
| Names and virtues of the surah | 11:07.9–23:54.0 | medium | "بسم الله الرحمن الرحيم سورة الفاتحة" at 11:12, then "السبع المثاني والقرآن العظيم" (12:16–12:51), "سورة الحمد" (13:35), "الرقية" (16:12): names and virtues of the surah, not one ayah. |
| Overview of all seven ayahs | 23:54.0–25:58.9 | medium | Ayahs 1–7 quoted in order with short comments (23:54 ayahs 1–4, 24:12 "أنعمت عليهم من النبيين", 25:28 ayah 7, 25:36 "مكة"): an overview of the whole surah. Reviewer may prefer to class it as a brief explanation of ayahs 1–7. |
| Ayah 1 explained | 25:58.9–33:00.0 | medium | Dense quotations of the basmala with its uses: 26:00 "قولوا … بسم الله", 27:08 "باسم الله", 29:35 Sulayman's letter (إنه من سليمان وإنه بسم الله الرحمن الرحيم), 30:43 "بسم الله وعلى ملة رسول الله", 31:40 "اذكر اسم الله وكل بيمينك". |
| Ayah 2 explained | 33:00.0–37:47.1 | low | New basmala at 33:00, then "الحمد لله … رب العالمين … الرحمن … الرحيم … مالك يوم الدين" glossed (33:13–33:35), then a long passage on the name الله and other names (قاهر، قوي، عزيز، اللطيف، الرحمن, 33:36–37:20), then "الحمد لله … رب العالمين، العالمين" (37:28). The name passage might instead belong to the basmala (ayah 1). |
| Ayah 3 explained | 37:47.1–38:03.1 | low | Short glosses of "الرحمن" / "الرحيم" (37:51–38:01). Ar-Rahman and ar-Rahim may also have been explained inside the basmala or name passages; very short candidate. |
| Ayahs 2–4 explained together | 38:03.1–39:21.5 | medium | Ayahs 2–4 together: رب العالمين / الرحمن الرحيم / مالك يوم الدين and "الخوف والرجاء" (38:03–38:55), then the hadith qudsi "قسمت الصلاة بيني وبين عبدي … الحمد لله رب العالمين … الرحمن الرحيم … مالك يوم الدين" (38:55–39:27). |
| Ayah 4 explained | 39:21.5–41:11.8 | high | "مالك يوم الدين" repeated, "ملك/مالك" (39:43), "يوم الجزاء" (39:57), "وما أدراك ما يوم الدين … يوم لا تملك نفس لنفس شيئا والأمر يومئذ لله" (40:01–40:18), "لمن الملك اليوم" (40:26). |
| Recap of ayahs 2–4 (explanation) | 41:11.8–41:50.8 | low | Recap "رب العالمين … الرحمن … الرحيم" (41:11) before ayah 5. Could be merged into ayah 5's lead-in or dropped. |
| Ayah 5 explained | 41:50.8–45:40.7 | high | "إياك نعبد … وإياك نستعين" quoted repeatedly (41:56–42:36, 42:54), hadith "حق الله على العباد أن يعبدوه ولا يشركوا به شيئا" (45:23–45:33), "إياك نعبد … وإياك نستعين" (45:33). |
| Ayah 6 explained | 45:40.7–47:07.1 | low | No clear quotation of "اهدنا" found, but 46:10–46:32 discusses "الصراط … دين الإسلام … وأن هذا صراطي مستقيما فاتبعوه ولا تتبعوا السبل". Start and end are the least certain of all. |
| Ayah 7 explained | 47:07.1–48:32.0 | medium | "غير المغضوب عليهم" with "اليهود" (47:32–47:57), "ولا الضالين … النصارى" (48:05–48:24) until the end. Start uncertain between 47:07 and 47:32 (no draft text in between). |

Uncertain: the lesson introduction (non-Arabic speech the draft can't read), every boundary to within a few seconds, and ayahs 2, 3 and 6. Only listening can settle them.

## On-device playback check (emulator, 2026-11-13)

The real app on an Android API 37 emulator, with the hash-checked recording and the **bundled candidates** (nothing injected). Tapping ayahs 1–7, then 3 and 1 while playing, every tap played its candidate explanation segment.

The emulator's actual audio output was captured, from the emulator alone, and each 3 s slice was found again in the original MP3:
- **Position:** every tap within 0.3 s of the expected point (one shared latency of −0.24 s), with 5 or 6 of 6 half-second windows on the expected timeline; deliberately wrong timing fails the check.
- **Loudness:** about −28 dBFS against −110 dBFS of silence after the stop.

Full table: `docs/DESIGN_IMPLEMENTATION_REPORT.md` → "Bug fix: Al-Fatiha ayah numbering and audible Tafsir playback". Playback stopped at the segment's end (see the report).

This proves the app plays the candidate moments of the original recording, audibly. It does **not** prove the candidates are right; only the owner's review does (all 7 are still unreviewed).

## Rights

| Question | Answer | Label |
|---|---|---|
| Use in development and emulator testing | Allowed | OWNER-STATED (C-26) |
| Bundling in the app, streaming, offline download | **Not allowed yet** | OWNER-STATED (C-26) |
| Written rights evidence | Not supplied (P-22) | — |

Consequences in the app: the recording is not in the APK. Debug builds play it only from a locally installed, hash-verified copy, and release builds can't play it at all (tested).
