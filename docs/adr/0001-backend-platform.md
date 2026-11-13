# ADR 0001: Backend platform

| Field | Value |
|---|---|
| Status | **Proposed.** Awaiting owner approval. Nothing has been created (Phase 0 spec §12) |
| Date | 2026-11-13 |
| Decider | Project owner |

## Context

The app is **offline-first**. Reading, listening, bookmarks and progress all work from on-device storage (Drift/SQLite plus files). The backend is needed for:

1. **Content delivery:** the catalogue, signed manifests for offline packages, and large files (PDFs, page images, audio). The library could reach hundreds of books and hundreds of hours of audio.
2. **Administration (CMS):** import, metadata, transcript review, alignment, rights, verification, publishing, version history and an audit log. A small editorial team uses it.
3. **Optional accounts:** syncing bookmarks and progress across devices. Reading doesn't need an account (master prompt §18).
4. **Security:** role-based access (editor, aligner, reviewer, admin), signed URLs for content with restricted rights, and an audit trail.

What drives the choice: download volume (audio dominates), a relational content model (books → volumes → chapters → pages → passages ↔ spans ↔ recordings), data ownership and portability, a small team with limited operations capacity, and cost.

## Options

| Criterion | A. Supabase (managed Postgres, Auth, Storage, Edge Functions) | B. Firebase (Firestore, Auth, Storage, Functions) | C. Custom API (Dart or TypeScript) + Postgres + S3-compatible storage | D. Self-hosted Supabase or Appwrite on a VPS |
|---|---|---|---|---|
| Fit with the relational model | **Strong** (Postgres, foreign keys, SQL migrations) | Weak (document store; joins and integrity done by hand) | Strong | Strong |
| Offline-first | Neutral: the client does offline itself; delta endpoints built as SQL or functions | Firestore's offline cache suits small documents, not libraries or files | Neutral | Neutral |
| Content delivery and egress cost | Storage + CDN; egress is billed above the plan quota | Egress billed | Free choice: e.g. object storage with **no egress fees** behind a CDN | Free choice |
| Authentication | Built in (email OTP, OAuth) | Built in | You build or buy it | Built in |
| Admin roles and security | Row-level security + roles in SQL; audit tables via triggers | Security rules; harder to audit | You write it all | Same as A |
| Data ownership and portability | **High** (standard Postgres; `pg_dump`; the open-source stack can be self-hosted later) | Low (proprietary format) | High | High |
| Backup and recovery | Daily backups on paid plans; point-in-time recovery as an add-on | Managed export | You run it | You run it |
| Operations load | Low | Low | **High** | Medium to high |
| Scalability for this product | Ample | Ample | Depends on you | Depends on the VPS |
| Lock-in | Low to medium | High | None | Low |

Costs change often, so they **must be re-checked on the vendors' pricing pages at decision time**. Order of magnitude from general knowledge (NOT VERIFIED for 2026): the managed options cost tens of dollars a month at small scale, and **egress for audio downloads becomes the main cost as usage grows**. That is the main reason to keep large media on egress-friendly storage behind a CDN.

## Proposed decision

**Option A (Supabase) for the database, auth, CMS API and roles, with large media files on S3-compatible object storage behind a CDN.** The media storage can be Supabase Storage at first and moved to a provider with no egress fees if download volume grows.

- The content database is standard Postgres: SQL migrations under version control, row-level security for editor, aligner, reviewer and admin roles, and audit triggers.
- Offline packages are **immutable, versioned, content-addressed files** (SHA-256 names) with **Ed25519-signed manifests**. The app checks every file, so the storage provider can be swapped without client changes.
- The client talks to a **thin, versioned content API** (catalogue, manifests, deltas, user-data sync), not straight to tables. This avoids lock-in and keeps the offline protocol stable.
- **CMS:** a Flutter web admin app or a small web app, decided in the CMS phase.

## Consequences

- Positive: relational integrity, portability, low operations load, built-in auth and roles.
- Negative: Supabase doesn't do offline sync itself. User-data sync is built on our own merge rules (UUIDv7, hybrid logical clocks, tombstones; see REFERENCE_PROJECT_EVALUATION).
- Risk: egress costs. Mitigations: content-addressed deduplication, delta updates, and a storage tier that can be swapped.

## Not decided here

The hosting region (data residency), the budget ceiling, which sign-in methods to use, and whether accounts are offered in the first release. These are listed in PHASE_0_DECISIONS §2.
