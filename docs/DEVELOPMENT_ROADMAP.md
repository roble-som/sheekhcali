# Development roadmap

Revised 2026-11-13 for the owner's Phase 0 specification. The phases follow master prompt §21, with one proposed change (P-10: the Quran text foundation moves earlier, because the Al-Fatiha demo depends on it). **A phase is complete only when its acceptance criteria have evidence.** A successful build is never enough.

Decision and blocker IDs (C-xx, P-xx) refer to [PHASE_0_DECISIONS.md](PHASE_0_DECISIONS.md).

---

## Phase 0: Discovery and foundation (this phase)

**Deliverables:** PROJECT_ARCHITECTURE · CONTENT_INVENTORY · PHASE_0_DECISIONS · DESIGN_SYSTEM_SPECIFICATION · QURAN_AND_AUDIO_ACCURACY · REFERENCE_PROJECT_EVALUATION · ADR 0001 · design/DESIGN_REFERENCE_INVENTORY · design/DESIGN_GAPS · design/concepts · this roadmap.

**Acceptance:**
- [x] All existing documentation and all six screenshots inspected.
- [x] Confirmed and pending decisions recorded.
- [x] EN/AR and RTL/LTR rules documented.
- [x] Quran accuracy and Al-Fatiha validation strategy documented.
- [x] Content and design gaps recorded.
- [x] No application code written, and no unverified content presented as authentic.
- [ ] **The owner has reviewed and approved this documentation** (gate to Phase 1).

---

## Phase 1: Design system and app shell

**Blocked by:** P-06 (visual direction), P-16 (contrast fixes), P-17 (navigation). P-02 (logo) and P-19 (Arabic name) can use clearly marked placeholders.

**Deliverables:**
- ✅ Rename to Sheekh Calinuur on Android, iOS, web and the app UI (plus the Linux and Windows window titles). The package ID is left unchanged until P-05.
- Theme tokens (`h.*`, `r.*`, semantic), type scale for EN and AR, spacing and radii.
- `en` and `ar` localisation with go_router routes.
- Home, Drawer, Quran reader shell, Ayah action sheet and Overflow menu, reproducing 01–06. The Quran text area shows a labelled placeholder until the text foundation phase; no Quran text is typed in.
- The 14 concept screens as static UI states with placeholder content, **only after P-06 approves them**.
- `docs/design/DESIGN_TOKENS.md`, `SCREEN_SPECIFICATIONS.md`, `COMPONENT_MAPPING.md`, and `docs/DESIGN_IMPLEMENTATION_REPORT.md`.

**Progress (2026-11-13, first increment):** foundation, tokens, components, EN/AR localisation, routing, and the Splash, Home, Drawer and Quran Reader shell (with sheet and menu) are built. See `docs/DESIGN_IMPLEMENTATION_REPORT.md`. **Second increment (2026-11-13):** 48 dp reader toolbar targets (C-18), Surah and Juz index, Library, Book details, rebuilt Settings with the Hijri adjustment, and Content sources & licences. **Still to build:** Book reader, Tafsir, lesson library, audio player, synced reader, Downloads, Offline library, Bookmarks and history, About. `SCREEN_SPECIFICATIONS` remains DESIGN_SYSTEM_SPECIFICATION §8 (as-built differences are listed in the implementation report).

**Acceptance:**
- A side-by-side comparison for each of 01, 02, 05 and 06. Every measurable property (position, size, colour, radius, type size) is within **±2 dp** and **ΔE ≤ 3**, or the deviation is listed with its reason. 03 and 04 are compared on the chrome only until the Quran text exists.
- Golden tests for every built screen in **EN-LTR and AR-RTL**, at text scale **1.0 and 2.0**, on two widths (360 dp and 412 dp). All pass in CI.
- No `left` or `right` in layout code (checked by a lint or grep).
- Every text and background pair passes WCAG AA (an automated contrast test over the tokens).
- Every interactive element is ≥ 48 dp, and every icon button has a semantic label in both languages.
- `flutter analyze` is clean and all tests pass.

---

## Phase 2: Book library and offline package engine

**Blocked by:** P-04 (backend) for remote content; P-01 and P-22 for real books. The engine is built and tested with **synthetic, clearly labelled test packages** until the real books arrive.

**Deliverables:**
- Drift `content.db` and `user.db` with migrations.
- Content-addressed file store, signed package manifest, downloader (queue, pause, resume, retry, integrity check).
- Library, Book details and Book reader (PDF page view; text view only for verified text), plus search over downloaded text.
- Bookmarks, notes, highlights and progress.
- CMS import (bulk and folder-based) in its minimum form.

**Acceptance:**
- Migration tests from schema v1 to the current version keep all `user.db` rows.
- Download a test package of at least 200 MB, kill the app at 30%, 60% and 90%: it resumes without re-downloading completed files, and the final SHA-256 matches.
- A corrupted file is detected and re-fetched; the previous good version is kept.
- With airplane mode on after download: open the book, turn to any page, search (the first result appears in **< 500 ms** on a mid-range device), bookmark, note, restart, and everything persists.
- Every supplied book appears in CONTENT_INVENTORY with a status from the C-11 vocabulary.

---

## Phase 3: Offline validation

**Deliverables:** `docs/OFFLINE_LIBRARY_TEST_REPORT.md`.

**Acceptance:** a written test run on a real Android device covers every published book: downloaded → airplane mode → opens and reads → search → notes → restart. No unnecessary network errors appear. Storage figures match on-disk sizes within 1%.

---

## Phase 3A: Quran text foundation (proposed to move here, P-10)

**Blocked by:** P-03 (source), P-07 (reviewer).

**Deliverables:** import tooling, a bundled Quran database, a checksum manifest, the cross-source report, continuous reading mode, and `docs/QURAN_VERIFICATION_LOG.md`.

**Acceptance:**
- 114 surahs and 6,236 ayahs, with every per-surah count matching the source metadata **and** the second source.
- 6,236 of 6,236 ayahs match the checksum manifest. The round-trip and display-path tests pass.
- The letter skeleton matches the second source exactly for every ayah. Every diacritic difference is resolved through the reviewed mapping or logged for review.
- The chosen font covers 100% of the code points in the text.
- A named qualified reviewer signs off a device review of the agreed page list.

---

## Phase 4: Al-Fatiha audio and Tafsir synchronisation

**Status 2026-11-13 (moved ahead by owner priority):** text import (Phase 3A scope for Al-Fatiha), reader, player, synchronisation engine and review workflow are built and tested; see DESIGN_IMPLEMENTATION_REPORT "Al-Fatiha". **Open:** the owner's text check and timestamp review (C-27), the written Tafsir edition (P-08), distribution rights (P-22), and a millisecond seek-accuracy measurement.

**Blocked by:** P-08 (the Tafsir edition; confirm the content of recording R3, which has arrived), P-22 (rights), P-07 (reviewer), and Phase 3A.

**Deliverables:** recording registration, the Tafsir import (page images plus reviewed text), transcript (AI draft, then verified), the CMS alignment workspace, the synchronised reader (screen 8.12), and `docs/FATIHA_VALIDATION_REPORT.md`.

**Acceptance** (QURAN_AND_AUDIO_ACCURACY §7.3):
- 100% of spans reviewed by a named reviewer who isn't the aligner.
- Seek error **≤ 150 ms at the 95th percentile** over 20 or more measured seeks on a real device.
- Playback from the start, 10 random seeks and 10 passage taps: the highlight matches the speech in every case, including in airplane mode.
- Stale or unverified mappings show no highlight (an automated test proves it).

---

## Phase 5: Expand the library and lessons

**Acceptance:** CONTENT_INVENTORY shows every supplied item with a final status (Published or Rejected with a reason). The import needs no code changes. Each lesson with a mapping passes the Phase 4 per-lesson checks.

## Phase 6: Full Quran reader

**Blocked by:** P-24 (mushaf page licence) for page mode; P-23 for translation.
**Acceptance:** all 604 pages render from the edition's own layout data, with no layout we computed ourselves. Juz, hizb and sajdah navigation is verified against the source. Bookmarks and history persist offline. The translation is labelled and attributed.

## Phase 7: Quran audio and study

**Acceptance:** reciter audio licences are recorded. Recitation is labelled separately from the Sheikh's lessons. Downloaded recitation plays offline. Ayah-by-ayah follow uses the reciter's published timing data, never estimates.

## Phase 8: Productivity (Khatmah, Itqan, statistics, Adhkar, prayer times, Qibla)

**Acceptance:** every dhikr has a recorded source reference (P-12). Prayer times match a reference calculator for the same method within 1 minute in 5 test cities. Qibla bearing is within 1° of the computed great-circle bearing.

## Phase 9: Production readiness

**Blocked by:** P-05 (package ID), P-21 (iOS).
**Acceptance:** a security review is done, accessibility is audited in both languages, performance meets its budgets (cold start < 2 s on a mid-range device, reader at 60 fps), and release builds are signed. The store listing names the content sources and their licences.
