# API v2 Cleanup Candidates

Status: C1 contract/documentation alignment for AC7.

Scope: destructive or narrowing API changes that must not land in v1. Current v1 contract tests freeze supported standings and player response fields; v1 may add optional fields only with documentation and tests.

## v1 Compatibility Guardrail

- Do not rename, remove, or narrow existing v1 response fields.
- Keep nullable fields nullable unless a v2 migration is opened.
- Keep current error responses shaped as `{ "error": { "code", "message", "statusCode" } }`.
- Keep `/v1/ready` returning `ok`, `source`, `version`, `checks.config`, and `now`.
- Keep production debug/test fixture behavior gated: `/debug/source/today` is hidden in production unless explicitly enabled, and `KBO_USE_TEST_LIVE_GAME` is ignored in production.
- Treat source-backed additions as additive only after official raw evidence and contract tests are updated.

## v2-Only Candidates

| Candidate | Current v1 field/route | Why it is destructive | Evidence required before v2 |
| --- | --- | --- | --- |
| Collapse duplicate standings routes | `/v1/standings`, `/v1/teams/standings` | Removing either route would break current clients. | Route usage audit and replacement client release. |
| Rename standings record fields | `wins`, `losses`, `draws`, `rank`, `streak`, `winRate`, `recentTen`, `gamesBack` | Renames or casing changes break current JSON decoders. | Official `TeamRankDaily` raw key/path mapping and client migration plan. |
| Remove standings metadata | `teamId`, `teamName`, `winRate`, `recentTen`, `gamesBack` | Some fields are parser-level official data even when app surfaces only a subset. | Consumer audit proving no v1 client reads them. |
| Normalize player DB record casing | snake_case fields inside `batting` and `pitching` records | Current player season endpoints expose SQLite column names; changing to camelCase is a wire break. | v2 DTO schema, migration docs, and player endpoint contract tests. |
| Hide player source metadata | `source`, `raw_source_id`, `created_at`, `updated_at` in player record objects | Removing these fields narrows the current player season response. | Explicit decision that source audit metadata moves to an internal/admin surface. |
| Tighten nullable numeric fields | Nullable player and standings stats | Current rows can contain `null` when official source values are absent. | Official raw evidence that the field is always populated for every supported phase. |
| Replace `player: null` with 404 | `/v1/players/:playerId/season` missing-player response | Current v1 returns HTTP 200 with `player: null`. | Client error-handling migration and v2 route contract. |
| Remove MVP local compatibility routes | `/games/today`, `/games/:gameId`, `/standings`, `/health`, `/ready` | Existing local tooling may still call unversioned routes. | Tooling/client audit and v2 deprecation notice. |
| Change generic 500 shape | `INTERNAL_ERROR` with generic message | H1 intentionally prevents raw error leakage while preserving error shape. | New cross-route error contract and client handling update. |
| Expose production debug or fixture controls differently | `/debug/source/today`, `KBO_USE_TEST_LIVE_GAME` | Current production safety gate is part of hardened behavior. | Security review and private/admin route design. |
| Adopt deferred non-official fields | `boxScore.hits/errors/walks`, `boxScore.linescore`, `lineupPreview`, `analysis` | Adding guessed values or changing null/empty placeholders would imply unsupported semantics. | Official raw source, field inventory update, mapper tests, and contract tests. |
| Move stale/cache metadata into top-level response | current game `sourceMeta` and service cache behavior | Adding or relocating stale metadata can change client interpretation of data freshness. | O1 observability decision, response schema proposal, and stale-cache test evidence. |

## Current Non-Candidates

- `/v1/ready` readiness shape is not a cleanup target; H1 made it a real config validation surface.
- `/metrics` remains an operational surface decision. If O1 implements it, production exposure must stay gated or private.
- Official-source fields marked `yes` in `CONTEXT/official-source-field-inventory.md` are not v2 cleanup candidates unless the raw evidence or consumer contract changes.
