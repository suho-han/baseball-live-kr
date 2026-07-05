# Final Regression Sentinel Live-Window Status (G006)

Checked: 2026-07-05T14:09:04Z / 2026-07-05T23:09:04+09:00

Source: `https://api.baseball-live.kro.kr/v1/games/today`

Result: no live games available. The production API returned 110 games with statuses `final`, `cancelled`, and `scheduled`, and zero current `status=live` games, so the approved Phase 7 sentinel cannot be captured without fabricating live-surface evidence.

Superseded for this run: explicit user steering replaced the production-live Phase 7 gate with G007 staging live simulation, with production import/revalidation deferred in `evidence/perf-sentinel/production-import-follow-up.md`.
