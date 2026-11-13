# Project architecture

Phase 0, first written 2026-11-13 and revised the same day after the owner's Phase 0 specification. This document describes the current state and a **proposed** architecture. Nothing below has been built. Decisions are tracked in [PHASE_0_DECISIONS.md](PHASE_0_DECISIONS.md) (C-xx confirmed, P-xx pending).

## 1. Current state

### This repository (`sheekhcali`)

| Item | Finding | Label |
|---|---|---|
| Git | Branch `main`, one commit `452a273 Initial commit` (README only); the Flutter template is untracked; remote `github.com/roble-som/sheekhcali` | VERIFIED |
| Flutter project | A `flutter create` template: `lib/main.dart` is the counter demo; `test/widget_test.dart` | VERIFIED |
| Dependencies | `cupertino_icons` only | VERIFIED |
| Toolchain | Flutter 3.47.9 stable, Dart 3.13.7 (`sdk: ^3.13.7`) | VERIFIED |
| App identity | Android `applicationId com.example.sheekhcali`, label `sheekhcali`; iOS display name `Sheekhcali` | VERIFIED. All must change |
| Assets, fonts, content | None | VERIFIED |
| Offline functionality | None | VERIFIED |
| Disk | 292 GB free on `/` | VERIFIED |
| ffmpeg / ffprobe | Not installed | VERIFIED. Needed for the audio pipeline |

### Previous project for the same Sheikh (`../quraan-app`)

Per C-01 it is a **reference only**; its product decisions don't apply here. It is the same product under earlier names: Android label **"Shiiq Calinuur"**, Dart package `shiiq_calinuur`, later rebranded **"Diini"** (its D-32), with `applicationId com.quraanapp.quraan_app_mobile`. It has about 22,800 lines of Dart across:

| Part | What it contains | Reuse value |
|---|---|---|
| `packages/diini_core` (pure Dart, tested) | Content model, alignment validator (spans bound to one text revision and one audio hash), Arabic and Somali search normaliser, audio↔text sync engine, user-data merge (UUIDv7, HLC last-writer-wins, tombstones), content lifecycle, permissions | **Ideas: high.** 260 tests pass. But each span links to only one paragraph, and there is no Quran or Tafsir model. See [REFERENCE_PROJECT_EVALUATION.md](REFERENCE_PROJECT_EVALUATION.md). Copying code needs P-09 |
| `packages/diini_ui` | The design system for the *Diini* design | Low. That design differs from these screenshots |
| `apps/mobile` | The older reader with word-timing playback | Low |
| `tools/demo_server` | A Dart demo backend, explicitly "not production" | Medium, as a local CMS stand-in |
| `docs/` | 52 recorded owner decisions, specs for alignment validation, normalisation, lifecycle and permissions, and an OpenAPI contract | **High.** Many master prompt questions are already answered there |

Its owner decisions that conflicted with this project, now resolved:

| Previous decision | Sheekh Calinuur | Resolution |
|---|---|---|
| D-02: Quran text is **out** of the MVP | Quran is essential | **Quran in scope (C-03)** |
| D-32: display name "Diini" | "Sheekh Calinuur" | **Sheekh Calinuur (C-02)** |
| D-28: UI in Arabic and English | English and Arabic only | **The same outcome, confirmed again (C-04)** |
| P2-01: a 23-page Diini design | The six screenshots here | **The screenshots (C-06)** |
| D-01: the Sheikh mostly does sharh (reads the Arabic matn, explains in Somali); span kinds `reading`, `explanation`, `intro`, `qa` (D-30) | §8.3: "The Sheikh may explain a paragraph without reading its exact wording… implement human-assisted passage mapping" | The concept is kept, but it must be extended to many-to-many and checked against a real recording |

## 2. Proposed architecture

### 2.1 Overall shape

```
┌───────────────────────────── Flutter app (Android, then iOS) ─────────────────────────────┐
│ presentation (screens, widgets) ─▶ application (Riverpod notifiers) ─▶ domain (entities,  │
│ use cases, pure Dart) ◀─ data (repositories: local-first, remote second)                  │
│        local: Drift content.db + user.db, filesystem package store                        │
│        remote: Dio → Content API (catalogue, packages, deltas, user sync)                 │
│        audio: just_audio + audio_service; sync engine reads alignment spans               │
└───────────────────────────────────────────────────────────────────────────────────────────┘
                 │ HTTPS: signed package manifests (Ed25519) + per-file SHA-256
┌──────────── Backend: Content API + object storage/CDN + CMS (admin web) ──────────────┐
│ import pipeline: upload → extract/OCR → review → transcribe (draft) → align (human)   │
│ → verify → publish immutable release → build offline packages                         │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

**Pending (P-04): the backend.** The CMS, bulk import, publishing and downloads all need a server and storage. Supabase is **a candidate only** (C-09). The full evaluation is in [ADR 0001](adr/0001-backend-platform.md) (Proposed). Short version:

| Option | Fits when | Cost |
|---|---|---|
| **Supabase** (Postgres, storage, auth, row-level security) + a Flutter web admin | A small team that wants Postgres and SQL migrations without running servers | Free tier, then about $25 per month plus storage and egress |
| Firebase (Firestore, Storage, Auth) | Google-first; but Firestore fits the relational content model (§14) poorly | Pay as you go |
| A custom API (Dart or TypeScript) on Postgres + S3-compatible storage | Full control; you also run it | VPS about $10–40 per month, plus your own operations work |

**Proposed in ADR 0001:** Supabase (Postgres, auth, roles) with large media on S3-compatible storage behind a CDN, reached through a thin versioned content API. Nothing is created in Phase 0.

### 2.2 Flutter modules

The feature folders follow master prompt §13. Rules:

- `features/<name>/{presentation,application,domain,data}`. Features don't import one another's `data` or `presentation`.
- `core/` holds cross-cutting concerns: database, network, storage, audio, logging, errors, theme and tokens.
- Pure-Dart logic (alignment, normalisation, sync, lifecycle) lives in a **`packages/calinuur_core`** package, so it's tested without Flutter and can be shared with an admin app. Its design draws on the `diini_core` evaluation. Whether code is ported or rewritten depends on P-09.
- **Localisation:** `flutter_localizations` + `intl` ARB files for `en` and `ar` only (C-04). Direction comes from the locale. Content blocks set their own direction (DESIGN_SYSTEM_SPECIFICATION §6).
- State: Riverpod 3 without code generation (the previous D-33 found `riverpod_generator` conflicts with `build_runner` 2.17.1). Routing: go_router.

### 2.3 On-device storage

Two Drift databases, following the previous D-34:

- **`content.db`** is rebuildable from downloaded packages: books, volumes, chapters, pages, passages, lessons, recordings, transcript segments, alignments, Tafsir, Quran text. It's safe to rebuild if corrupted.
- **`user.db`** is never overwritten by content updates: bookmarks, notes, highlights, reading and lesson progress, downloads, Khatmah and Itqan.

Large files go on the filesystem, in a content-addressed store:

```
<app-support>/packages/<bookId>/<releaseId>/manifest.json   (signed)
<app-support>/blobs/sha256/<ab>/<hash>                       (PDF, EPUB, page images, audio, images)
```

Blobs are shared between releases, so a new version downloads only the files that changed (master prompt §7.6). A download is written to `*.part`, its SHA-256 is checked, then it is renamed into place atomically. A failed download never deletes the previous good copy (§7.5).

### 2.4 Content model

This follows master prompt §14, with the changes the previous project found necessary:

- **Stable IDs (UUIDv7)**, separate from display order, so bookmarks, notes and alignments survive edits.
- **Immutable text revisions.** `BookPassage` text is never edited in place; an edit creates a new revision. A `PassageAlignment` points to **one passage revision and one recording checksum**. If either changes, the alignment is invalid and **nothing is highlighted** (no false sync, §3 priority 4).
- **Alignment spans with a kind**: `reading` | `explanation` | `intro` | `qa`. Spans and passages are linked many-to-many through a join table: one span can cover several passages, and one passage can be explained across several spans or lessons (§8.3).
- **Separate entities**: Quran ayah, Tafsir passage, book passage, transcript segment, translation and editorial note are separate tables with source and attribution. They are never merged into one text field (§9, §19).
- **Content status** uses the C-11 vocabulary (Missing · Imported · Processing · Needs verification · Verified · Approved for publication · Published · Rejected), plus an `origin` field (`source`, `ai_draft`, `machine_alignment`, `human`). The reader highlights only verified mappings and labels AI drafts. See [QURAN_AND_AUDIO_ACCURACY.md](QURAN_AND_AUDIO_ACCURACY.md).
- **Rights record per title**: may it be distributed publicly, offline, with audio? The publish gate checks it (§19).
- **Book collection membership**: "Kutubta Sheekh Calinuur" is a curated collection, and its completion status comes from verified metadata, not from the presence of uploaded audio (§6.3).

The full table list is in master prompt §14. The Phase 2 deliverable is a Drift schema with a migration test.

### 2.5 Audio and text sync at runtime

The player emits a position stream. A pure-Dart `SpanIndex`, built once per recording from alignments sorted by start time, finds the active spans at that position. The reader subscribes to the active passage IDs and handles paging and scrolling. Lookup is a binary search, so long recordings stay cheap. Seeking uses the same lookup. Tapping a passage seeks to its first `reading` span (previous D-26). None of this logic lives in a widget (§13).

### 2.6 Quran data

**Pending (P-03, P-24).** Proposed: Tanzil Uthmani 1.1 (verbatim with attribution, VERIFIED from tanzil.net/download), cross-checked against a second source at build time. Mushaf page mode needs KFGQPC or Quran Foundation font and layout data, and its licence is unclear. The full strategy is in [QURAN_AND_AUDIO_ACCURACY.md](QURAN_AND_AUDIO_ACCURACY.md). The Quran text is bundled into the app and checked against a checksum manifest, so Quran reading works offline from the first launch.

### 2.7 Transcription and alignment pipeline (server or workstation side)

1. Store the original recording unchanged and record its checksum.
2. Make a playback copy (AAC M4A) and check that its duration is within 50 ms of the original's timeline (previous D-37), so timestamps stay valid.
3. Make a draft transcript with Whisper large-v3 or WhisperX. Somali accuracy must be **measured on these actual recordings** before relying on it, and every draft is labelled AI.
4. Forced alignment applies only to `reading` spans, where the Sheikh reads the Arabic matn verbatim. `explanation` spans are mapped by a person in the CMS alignment workspace.
5. A reviewer verifies the work, it is published, and the offline package is rebuilt.

This machine has no ML-capable GPU, so Whisper here would be slow. A cloud GPU or a hosted speech-to-text service needs a decision when Phase 4 arrives.

## 3. Open architecture decisions

These have moved to [PHASE_0_DECISIONS.md](PHASE_0_DECISIONS.md):

| Earlier ID | Now |
|---|---|
| A-01 Quran in scope | **Confirmed** (C-03) |
| A-02 Quran text and mushaf source | P-03, P-24 |
| A-03 Backend | P-04, [ADR 0001](adr/0001-backend-platform.md) |
| A-04 Fresh start versus continuing `quraan-app` | **Confirmed** fresh (C-01); code reuse depends on P-09 |
| A-05 Package ID | P-05 (§9 of the decisions) |
| A-06 Content reviewers | P-07 |
