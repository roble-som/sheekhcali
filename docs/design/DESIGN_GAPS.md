# Design gaps

Screens and details that are required but that the six reference screenshots don't show. Revised 2026-11-13 for the owner's Phase 0 specification. Decisions are tracked in [PHASE_0_DECISIONS.md](../PHASE_0_DECISIONS.md). The proposed answers for screens with no reference are in [DESIGN_SYSTEM_SPECIFICATION.md](../DESIGN_SYSTEM_SPECIFICATION.md) §8 and in `concepts/`. They are **proposals awaiting approval (P-06), not approved designs**.

## Screens (Phase 0 spec §6, 17 screens)

| # | Screen | Reference | Status |
|---|---|---|---|
| 1 | Splash | None | Concept proposed |
| 2 | Home | 01 (top part only) | Below-the-fold tiles not shown (G-13) |
| 3 | Navigation drawer | 02 | New rows proposed (G-12) |
| 4 | Quran reader | 03–06 | Light mode (G-09) and continuous mode not shown |
| 5 | Surah and Juz navigation | None | Concept proposed |
| 6 | Islamic book library | None | Concept proposed |
| 7 | Book details | None | Concept proposed |
| 8 | Book reader | None | Concept proposed |
| 9 | Tafsir reading screen | None | Concept proposed |
| 10 | Sheikh lesson library | None | Concept proposed |
| 11 | Sheikh audio player | None | Concept proposed |
| 12 | Audio-synchronised Tafsir reader | None | Concept proposed (architecture only; no real content, C-12) |
| 13 | Downloads | None | Concept proposed |
| 14 | Offline library | None | Concept proposed |
| 15 | Bookmarks and reading history | None | Concept proposed |
| 16 | Settings | None | Concept proposed |
| 17 | About Sheekh Calinuur | None | Concept proposed; the text must come from the owner |

**14 of 17 screens have no reference.** Only Home, Drawer and the Quran reader are covered, and Home only partly.

## Questions

| ID | Question | Status |
|---|---|---|
| G-01 | Keep both visual identities? | **Answered: keep both** (C-05) |
| G-02 | Which style for the screens with no reference? | **Proposed:** browse screens use Home (H), reading and listening screens use Reader (R). Pending P-06 |
| G-03 | "Quran Tabsera" → Sheekh Calinuur; may the medallion logo be used? | The name is answered (C-02). **The logo's rights are pending (P-02)** |
| G-04 | Mushaf rendering source and licence | Pending (P-24); see QURAN_AND_AUDIO_ACCURACY §2 |
| G-05 | UI languages | **Answered: English and Arabic only** (C-04) |
| G-06 | Is the grey drawer banner a placeholder or content? | Pending |
| G-07 | "Recitation Correction" and "Live Chat" | Pending (P-18); proposed: hide behind a flag |
| G-08 | Latin UI font (looks like Inter) | Pending; confirm the font name or file |
| G-09 | Reader light mode (a menu item in 06, not shown) | Pending; needs a reference or approval of a proposal |
| G-10 | Home dark mode | Not in the references; proposed: Home stays light until a design is approved |
| G-11 | Arabic UI font | Proposed: Noto Sans Arabic or IBM Plex Sans Arabic (UI) + Noto Naskh or Amiri (content) |
| G-12 | Drawer and Home entries for Library, Lessons, Tafsir and Downloads | Proposed in DESIGN_SYSTEM_SPECIFICATION §7 (P-17) |
| G-13 | Home tiles below the fold (two tile tops are visible in 01) | Pending: which features, and in what order? |
| G-14 | Arabic spelling of the app name and the Sheikh's name | Pending (P-19); never transliterated by us |
| G-15 | Device and scale confirmation for dp values | Pending (P-13) |
