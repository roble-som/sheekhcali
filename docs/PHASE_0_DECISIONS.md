# Phase 0 decisions

Last updated 2026-11-13 (Phase 1 approval recorded). This is the single record of what is decided and what is not. A decision made only in chat doesn't count until it's written here.

**Statuses:** Confirmed (the owner stated it) · Pending (needs the owner) · Proposed (a recommendation awaiting approval).
**Evidence labels:** VERIFIED · PARTIALLY VERIFIED · NOT FOUND · NOT TESTED · BLOCKED.

---

## 1. Confirmed decisions

Source: the owner's Phase 0 specification (2026-11-13) and the master prompt.

| ID | Decision | Source |
|---|---|---|
| C-01 | `sheekhcali` is the official project. `../quraan-app` is a **reference only**: no wholesale copying, and its product decisions don't carry over | Phase 0 spec §2 |
| C-02 | The official product name is **Sheekh Calinuur** | Spec §2; master prompt §2 |
| C-03 | **Quran is essential and in scope.** This supersedes the reference project's D-02 | Spec §2 |
| C-04 | Interface languages are **English and Arabic only**. **No Somali UI** in this version. Somali *content* (the Sheikh's speech and transcripts) is still supported | Spec §4 |
| C-05 | Both visual identities are kept: Home in **green and gold**, Reader and drawer in **teal**. Not forced into one scheme | Spec §5 |
| C-06 | The six screenshots are the primary design references; missing details aren't invented | Spec §5 |
| C-07 | Flutter for Android and iOS | Spec header |
| C-08 | Phase 0 is documentation only: no screens, features, backend, commits or pushes | Spec §15 |
| C-09 | Supabase is **a candidate only**. The recommendation lives in an ADR | Spec §12 |
| C-10 | Package and bundle IDs are **not confirmed** and must not be invented | Spec §12 |
| C-11 | Content statuses: Missing · Imported · Processing · Needs verification · Verified · Approved for publication · Published · Rejected | Spec §11 |
| C-12 | Al-Fatiha is the first audio and Tafsir demonstration. Without real materials, **only the architecture and interface spec** are prepared | Spec §8 |
| C-13 | Never fabricate Quran, Tafsir, book text, the Sheikh's speech, transcripts, timestamps or mappings | Spec §7, §8; master prompt §19 |
| C-14 | Offline-first. Local content needs no account; cloud sync is optional | Master prompt §18 |
| C-15 | **Phase 1 approved.** Build the foundation and the Splash, Home, Drawer and Quran Reader screens, following the six screenshots, the Design System Specification and the concept board, with clearly marked placeholders for missing assets and unverified religious content | Owner's Phase 1 approval, 2026-11-13 |
| C-16 | The Design System Specification and concept board are approved as the visual direction. This closes P-06, and with them DV-01 and DV-02 (P-16) and the DV-05 drawer rows (P-17) | Same approval: "Follow the approved Design System Specification and concept board" |
| C-17 | The Al-Fatiha recording stays protected and out of Git. `.gitignore` now excludes `/shiiq_mp3/` and common audio extensions | Same approval §8 |
| C-18 | Reader toolbar icons keep the 40 dp visual pitch, with a **48 × 48 dp touch target** each. With a 40 dp pitch, neighbouring targets overlap by 8 dp; a tap in an overlap goes to the nearer icon (`ToolbarActionStrip`). This closes DV-07 | Owner, Phase 1 increment 2 approval, 2026-11-13 |
| C-19 | Umm al-Qura stays the provisional Hijri method (P-11 provisional) | Same |
| C-20 | Arabic-Indic digits stay in Arabic interface mode (P-14 provisional) | Same |
| C-21 | Inter stays the provisional English font (G-08 provisional) | Same |
| C-22 | The current Quran reader light theme stays, provisionally (G-09 provisional) | Same |
| C-23 | New Home tiles order: Library, then Sheikh's Lessons (closes G-13 for these tiles) | Same |
| C-24 | Placeholders stay clearly labelled for the missing logo, illustrations and other unapproved assets | Same |
| C-25 | **P-03 approved:** Tanzil Uthmani text, version 1.1, is the Quran text source. Verbatim only (no changes), credit "Tanzil Project" with a link to tanzil.net | Owner answer, 2026-11-13 (Al-Fatiha task) |
| C-26 | Recording R3 (`shiiq_mp3/003-الفاتحة 1-آخرها.mp3.mpeg`) is, per the owner, **Sheikh Calinuur's own Tafsir of Al-Fatiha**. It is approved **for development and emulator testing only: not bundled, not distributed**. This partly answers P-08 and P-22 | Same |
| C-27 | **P-07: the owner is the reviewer** for the Al-Fatiha Tafsir timestamps and the on-device Quran text check. Until the owner signs off, every mapping stays pending and nothing is highlighted from this recording | Same |
| C-28 | A local draft transcript (whisper.cpp, run on this machine only) is allowed as a starting point for the reviewer. It is never published or shown as content | Same |

## 2. Pending decisions

| ID | Question | Recommendation | Blocks |
|---|---|---|---|
| P-01 | Where are the Sheikh's books, recordings and Tafsir? Is there a list of completed books? | — | Phases 2, 4, 5 |
| P-02 | **Branding assets:** may the medallion logo seen in 01 and 02 be used? Is "Quran Tabsera" your own earlier app? Please supply source files (SVG or PNG ≥ 1024 px) | — | The splash, drawer, Quran card and About screen use placeholders until then |
| P-03 | **Closed by C-25.** Quran text source | **Tanzil Uthmani 1.1** as the primary text, plus an independent cross-check source ([QURAN_AND_AUDIO_ACCURACY §2](QURAN_AND_AUDIO_ACCURACY.md)) | Phase 6 and Al-Fatiha |
| P-04 | Approve [ADR 0001](adr/0001-backend-platform.md): backend | Supabase (Postgres, auth, roles) + S3-compatible media behind a CDN | CMS, sync, downloads at scale |
| P-05 | Package and bundle IDs | See §9 | First store build |
| P-06 | **Closed by C-16 (2026-11-13).** Visual direction for the screens with no reference: approve or change [DESIGN_SYSTEM_SPECIFICATION](DESIGN_SYSTEM_SPECIFICATION.md) and `design/concepts/` | Browse = Home identity; reading and listening = Reader identity | Phase 1 |
| P-07 | **Answered for Al-Fatiha by C-27** (owner). Named, qualified reviewers for Quran text, Tafsir and OCR, Somali transcripts and mappings | Record them in the CMS; the aligner never reviews their own work | Publishing any religious content |
| P-08 | Which Tafsir (and which edition) R3 follows. Confirm that R3 is the Sheikh's Al-Fatiha lesson. Are there recordings 001 and 002? | — | The Al-Fatiha demonstration |
| P-09 | Permission to port code from `quraan-app`, whose README says "proprietary, all rights reserved" and whose GitHub org is `online-learningg` | Port only with written confirmation | Reuse ([REFERENCE_PROJECT_EVALUATION](REFERENCE_PROJECT_EVALUATION.md)) |
| P-10 | Phase order: the Al-Fatiha demo needs verified Quran text, so a **minimal Quran text foundation** must come before Phase 4 | Move "Quran text import and verification" to straight after Phase 2 (see the roadmap) | The roadmap |
| P-11 | Default Hijri calculation method, and the ±day adjustment | Umm al-Qura by default, plus a user adjustment of ±2 days. **Phase 1 uses Umm al-Qura provisionally** (`hijri` 3.0.1, BSD-2), which reproduces the reference date (12 Nov 2026 = 2 Jumada al-Thani 1448, unit-tested). The ±day adjustment exists in code; the UI for it is not built | Home date |
| P-12 | Source of each Dhikr of the Day (text, reference, translator). Who wrote the bracketed translation in 01? | Show the reference on the card (DV-03) | The Home dhikr |
| P-13 | Reference device model, or a full-resolution screenshot, to confirm the dp scale | — | Exact dimensions |
| P-14 | Arabic UI digits: Arabic-Indic (٠١٢) or Western (012)? | Arabic-Indic in Arabic UI text; Western for player time codes. **Phase 1 implements the recommendation behind one switch** (`kArabicIndicDigitsInArabicUi`) | Arabic UI |
| P-15 | What a tap on the Quran card does: open the index, or resume the last page? | Resume if there's history; otherwise open the index | Home |
| P-16 | **Closed by C-16 (2026-11-13).** Approve the contrast fixes DV-01 and DV-02 | Approve | Phase 1 tokens |
| P-17 | **Closed by C-16 (2026-11-13).** Drawer and Home additions for Library, Lessons, Tafsir and Downloads (DV-05) | As in DESIGN_SYSTEM_SPECIFICATION §7 | Navigation |
| P-18 | "Recitation Correction" and "Live Chat" in the drawer: build, hide or remove? | Hide behind a feature flag until specified | Drawer |
| P-19 | **Arabic spelling of the Sheikh's name and of the app name** (R3's ID3 artist tag reads "الشيخ علي نور"; please confirm whether this is the official form), and the English and Arabic names of the collection "Kutubta Sheekh Calinuur" (a Somali phrase in an EN/AR UI) | The owner supplies them; nothing is transliterated by us | Arabic UI, splash, About |
| P-20 | Are accounts in the first release, and which sign-in methods? | Defer accounts until after the offline MVP | Sync |
| P-21 | iOS: Apple developer account and Mac or cloud macOS CI (no Mac on this machine) | Cloud macOS CI | iOS builds |
| P-22 | Rights evidence for each book and recording (public, offline, audio) | A rights record per title | Publishing |
| P-23 | The English translation of meanings to license | Choose in Phase 6 after a licence review | Translation feature |
| P-24 | Mushaf page mode licence: KFGQPC permission, or Quran Foundation font and image terms | Ask KFGQPC in writing; Quran Foundation as a fallback | Page mode (screenshot 03) |
| P-25 | Review mode: in debug/testing builds, may a tap on an ayah with no reviewed segment play its AI-assisted **candidate**, labelled "Unreviewed AI candidate · … · not verified"? (Built this way on 2026-11-13 so the owner can hear and judge each segment; release builds can't play R3 at all) | Keep it for review; never in release; remove once all seven are reviewed | Owner review of R3 |
| P-26 | Full Quran text: all 114 surahs were imported on 2026-11-13 under C-25 (same verified source bytes, every ayah cross-checked letter by letter against Quran Foundation `text_uthmani`, metadata cross-checked), with the basmala display rule in QURAN_AND_AUDIO_ACCURACY §3. Confirm, and name the qualified reader for the on-device check (P-07) | Keep; the reader check list in QURAN_AND_AUDIO_ACCURACY §3 applies | Publishing the full reader |

## 3. Missing content

Details are in [CONTENT_INVENTORY.md](CONTENT_INVENTORY.md).

| Item | Status |
|---|---|
| Islamic books (any format) | NOT FOUND |
| Tafsir documents | NOT FOUND |
| Al-Fatiha recording by the Sheikh | **FOUND (R3), unconfirmed**: `shiiq_mp3/`, 48:32. Content not yet confirmed by listening |
| Recordings | 3 found: two Ajurrumiyyah (grammar) in the reference project, one Al-Fatiha ("003") here |
| Transcripts | NOT FOUND. The reference project's timing files are unverified drafts |
| Rights documents | NOT FOUND |
| Dhikr texts with references | NOT FOUND |
| About text and the Sheikh's biography | NOT FOUND |

## 4. Missing design assets

| Asset | Seen in | Status |
|---|---|---|
| Logo / medallion (source file) | 01, 02 | NOT FOUND (P-02) |
| Mosque photo (dhikr background) | 01 | NOT FOUND. Rights needed |
| Khatmah and Prayer & Qibla illustrations | 01 | NOT FOUND |
| Further Home tiles below the fold | 01 | Not shown (G-13) |
| Surah header ornament | 03, 06 | NOT FOUND |
| Custom drawer icons | 02 | NOT FOUND. Material Symbols can stand in |
| Reader light mode | 06 (menu item only) | Not shown (G-09) |
| Home dark mode | — | Not shown (G-10) |
| Latin UI font confirmation | 01–06 | Looks like Inter (G-08) |
| Mushaf font and page layout | 03–06 | Licence BLOCKED (P-24) |
| 14 of the 17 required screens | — | No reference; proposed in DESIGN_SYSTEM_SPECIFICATION §8 and `design/concepts/` |

## 5. Quran source requirements

Summary; the full detail is in [QURAN_AND_AUDIO_ACCURACY.md](QURAN_AND_AUDIO_ACCURACY.md).

- A documented source, with its version, licence text, SHA-256 and retrieval date.
- Uthmani script (Hafs, Madinah mushaf), stored **byte for byte**, with **no Unicode normalisation**.
- Automated checks: 114 surahs, 6,236 ayahs, per-surah counts, basmala rules, juz, hizb and sajdah positions. Every expected value comes from the source data and is cross-checked against a second source.
- Checksum manifest, round-trip test and display-path test, run in CI.
- Device review of a fixed page list by a qualified reader, with the result recorded.
- Page mode only with layout data from the font's own edition; **page boundaries are never computed by us**.
- Unverified text is never shown as Quran.

## 6. Audio and Tafsir verification requirements

- Original recordings are immutable and identified by SHA-256. Playback copies stay on the original's timeline (duration ≤ 50 ms off, offset ≤ 10 ms; to be confirmed on a device).
- Transcripts are labelled Draft (AI) until a reviewer verifies them. The speech-to-text tool is chosen by measured accuracy on the Sheikh's own audio.
- Mappings are typed spans (`reading` / `explanation` / `intro` / `qa`), linked many-to-many to typed targets, and bound to exact text and audio versions. A reviewer who isn't the aligner checks them. Only verified mappings are highlighted.
- Tafsir is stored with its edition, volume, page and ayah range. OCR stays "Needs verification" until reviewed against the page image.

## 7. Technical risks

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| T-01 | No books or Tafsir supplied, so the core value can't be shown | Critical | P-01. Build the content pipeline with synthetic test data, clearly labelled |
| T-02 | Mushaf page fonts and layout licence unclear (KFGQPC) | High | P-24. Continuous mode as the fallback |
| T-03 | Wrong highlight (audio-text mismatch) | Critical | Version-bound spans, a validator, human review, device seek tests |
| T-04 | Quran text altered by normalisation, a font or a copy path | Critical | Byte preservation, checksums, display-path test, glyph coverage |
| T-05 | Somali speech-to-text quality unknown | High | Measure the word error rate on the Sheikh's audio before adopting a tool; human transcription as the fallback |
| T-06 | Alignment work underestimated (hours of review per hour of audio) | High | Measure on the first lesson; plan staffing from the measurement |
| T-07 | Storage and egress cost of large audio libraries | Medium | Content-addressed files, delta updates, egress-friendly storage (ADR 0001) |
| T-08 | Arabic rendering defects (shaping, bidi, line breaking) on some devices | High | Golden tests in both languages; review on real devices |
| T-09 | Rights unclear for books, recordings and assets | Critical | A rights record per title and a publish gate (P-22) |
| T-10 | iOS not buildable here (no Mac) | Medium | Cloud macOS CI (P-21) |
| T-11 | Scale assumption wrong (dp) | Low | P-13 |
| T-12 | Dependency drift: pub.dev versions change, some packages are retracted or end-of-life | Medium | Exact pins, releases at least 14 days old, re-checked when added |
| T-13 | Two visual identities feel inconsistent | Medium | Strict identity rule (browse versus read), shared spacing and type |
| T-14 | `quraan-app` code reuse rights unclear | Medium | P-09 |
| T-15 | Seeking in variable-bitrate MP3s (R3) is imprecise on many Android players, which would put highlights out of step with the audio | High | Timestamps on the original's sample timeline; constant-bitrate playback copy; device seek test |
| T-16 | Media files (`shiiq_mp3/`, 13 MB) are untracked in the repo, and `git add .` would commit them | Medium | Add `shiiq_mp3/` (and any media folders) to `.gitignore` before the first commit; keep media in object storage |

## 8. Backend evaluation

Summary of [ADR 0001](adr/0001-backend-platform.md), status **Proposed**:

- Compared: Supabase · Firebase · a custom API on Postgres with object storage · self-hosted Supabase or Appwrite.
- **Proposed: Supabase** for Postgres, auth, row-level-security roles and the audit trail, with **large media on S3-compatible storage behind a CDN**, reached through a thin versioned content API and signed, content-addressed offline packages.
- Reasons: the content model is relational, the data stays portable (standard Postgres), the operations load is low, roles and audit are built in, and the storage tier can be swapped as egress grows.
- **Nothing has been created.** Pricing must be re-checked at decision time.

## 9. Package identifier requirements

Status: **not chosen** (C-10). The Android `applicationId` and iOS bundle ID **can't change after the first store release**, so choosing them needs:

1. **A domain you control** (for example, if you own `calinuur.com`, the ID would be `com.calinuur.app`). Reverse-DNS from a domain you don't own risks a conflict.
2. **Publishing history:** was any earlier app published? The reference project used `com.quraanapp.quraan_app_mobile` (label "Shiiq Calinuur"). If that app is on Google Play with users, keeping its ID lets them upgrade; a new ID means a new listing. Was "Quran Tabsera" published, and under which ID?
3. **Google Play developer account** (the account owner's legal name or organisation) and an **Apple Developer team** (organisation or individual).
4. **Format rules:** lowercase letters, digits and underscores in segments; at least two segments; no Java keywords. iOS: reverse-DNS, no underscores.

The current template value `com.example.sheekhcali` **must be replaced before any store upload**; Google Play rejects `com.example`.

## 10. Dependencies and blockers

| Phase | Blocked by |
|---|---|
| Phase 1 (design) | P-02 (logo; placeholders allowed), P-06, P-16, P-17, P-19 (Arabic name) |
| Phase 2 (library) | P-01 (books), P-04 (backend), P-22 (rights) |
| Quran text foundation | P-03, P-07 (reviewer) |
| Phase 4 (Al-Fatiha sync) | P-08 (Tafsir edition; confirm R3), P-22 (rights), P-07, P-03 |
| Mushaf page mode | P-24 |
| Store release | P-05, P-21 |
