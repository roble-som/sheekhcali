# Reference project evaluation: `../quraan-app`

Phase 0, 2026-11-13. This is an evaluation only; **no code has been copied** (Phase 0 spec §2). `quraan-app` is a reference project. Its product decisions (name "Diini", Quran out of scope, Somali-related choices, its 23-page design) **don't apply** to Sheekh Calinuur unless they're confirmed again in `PHASE_0_DECISIONS.md`.

**Evidence labels:** VERIFIED · PARTIALLY VERIFIED · NOT FOUND · NOT TESTED · BLOCKED.

## What was inspected

| Item | How | Result |
|---|---|---|
| `packages/diini_core` (pure Dart) | Read the main files; ran `dart test` | **260 tests, all passed** (VERIFIED 2026-11-13; log in the session scratchpad). About 3,400 lines of library code and 3,300 lines of tests |
| `docs/specs/alignment-validation-v1.json`, `text-normalisation-v1.json` | Read | Language-neutral test vectors, usable without the Dart code |
| `docs/requirements/decision-log.md`, `mvp-baseline.md`, `docs/discovery/phase-0-report.md` | Read | 52 decisions; useful reasoning; several superseded by this project |
| `apps/mobile`, `packages/diini_ui`, `tools/demo_server` | Directory listing and pubspec only | Not evaluated in depth: tied to the Diini design and a demo server |

## Ideas worth reusing (as ideas, re-implemented or deliberately ported later)

| Idea | Where | Quality | Limitations for Sheekh Calinuur | Recommendation |
|---|---|---|---|---|
| **An alignment bound to one text revision and one audio checksum.** Per-paragraph hashes detect text that changed after alignment, and stale paragraphs are never highlighted | `model/alignment.dart` (`paragraphHashes`, `staleParagraphs`), `alignment/validator.dart` | Good: fails closed (a review-fix test covers "missing paragraph hash fails closed"); covered by test vectors | **Each span links to exactly one `paragraphId`.** The master prompt §8.3 requires one span → many passages, and one passage → many spans across lessons. It has no Quran ayah or Tafsir passage as a target | Keep the principle. Redesign the span → target link as many-to-many, with typed targets: book passage, Tafsir passage, ayah range |
| **Span kinds** `reading`, `explanation`, `intro`, `qa` | `model/enums.dart`, D-30 | Good. They match how the Sheikh teaches (reads the matn, then explains) | The owner described this for the old project (D-01) and nobody has checked it against a recording | Adopt, pending a check against the first real recording |
| **Validator rules**: overlaps, gaps of 1 s or more as warnings, spans past the end of the recording, stale text, review status | `validator.dart` + JSON vectors | Good: 26 test cases; errors block review and warnings don't | Rules assume one paragraph per span | Reuse the JSON test vectors as the starting acceptance suite; extend them for many-to-many |
| **Position ↔ text lookup** (`SyncEngine`): binary search with prefix-max end times, paragraph play states (done / reading / explaining / up next / not linked) | `sync/sync_engine.dart` | Good: pure, offline, works for long recordings | Paragraph-only | Re-implement the same algorithm for typed, many-to-many targets |
| **Arabic search normaliser** producing *derived* text with an offset map back to the original; never touches authoritative text; doesn't depend on NFC order (shadda/fatha) | `text/normaliser.dart` + `text-normalisation-v1.json` | Good: covers Quranic annotation marks U+06D6–U+06ED and U+08D3–U+08FF; 75 test vectors | Folding choices (ى/ي, ة/ه, hamza carriers) need a qualified reviewer; it hasn't been tested on full Uthmani Quran text | Reuse the rules and vectors; test them against the chosen Quran source before adopting |
| **User-data sync**: UUIDv7 IDs, hybrid logical clock last-writer-wins, tombstones, per-device progress, "never move progress backward silently" | `sync/merge.dart`, `hlc.dart` | Good: 11 merge tests in `sync_merge_test.dart` | Assumes the old server contract | Adopt the policy (it meets "never overwrite newer local progress", spec §10); re-implement against the chosen backend |
| **Content lifecycle** Draft → In review → Changes requested → Approved → Published → Superseded, with an immutable release snapshot | `lifecycle/lifecycle.dart`, `lifecycle-v1.yaml` | Good | The statuses differ from Phase 0 spec §11 (Missing, Imported, Processing, Needs verification, Verified, Approved for publication, Published, Rejected) | Use the spec §11 statuses; keep the immutable-release idea |
| **Two device databases**: `content.db` (rebuildable) and `user.db` (precious) | D-34 | Sound | | Adopt (see PROJECT_ARCHITECTURE §2.3) |
| **Media never in Git**: hash manifest + fetch tool | D-47 | Sound | | Adopt for Sheikh recordings and books |
| **Version pins that avoid known conflicts**: `build_runner 2.17.1`, no `riverpod_generator`, no `drift_flutter`/`sqlite3_flutter_libs` (`+eol`) | `AGENTS.md` | Recorded as VERIFIED on 2026-11-10 | Registry state changes over time | Re-check on pub.dev when Phase 1 adds dependencies |

## What not to reuse

| Item | Reason |
|---|---|
| The Diini name, `diini_ui` design system, 23-page design | Superseded by the Sheekh Calinuur brand and these six screenshots |
| D-02 "Quran out of scope" | Superseded: Quran is essential |
| Its word-timing JSON files | Their own note says "NEEDS REVIEW — approximate timing from estimated alignment" |
| `applicationId com.quraanapp.quraan_app_mobile` | Not confirmed as owned or published; see PHASE_0_DECISIONS §9 |
| Demo server | Labelled "not production" by its own project |

## Compatibility

- Same toolchain: Flutter 3.47.9 / Dart 3.13.7 (VERIFIED in both repos).
- `diini_core` depends only on `characters 1.4.1`, `collection 1.19.1` and `crypto 3.0.8` (VERIFIED from its pubspec), so licensing and dependency risk is low.
- License: `quraan-app` README says "proprietary, all rights reserved", and the GitHub org is `online-learningg` (a different owner from `roble-som`). **Before porting any code, confirm that you have the right to reuse it in this repo.** This is pending decision P-09 in PHASE_0_DECISIONS.
