# Staging Live-Simulation Phase 7 Sentinel (G007)

Generated: 2026-07-05T23:34:00+09:00

Phase 7 condition was changed by explicit user steering from a third production live-game window to a staging/local live simulation. The simulation uses the packaged local backend with `KBO_USE_TEST_LIVE_GAME=1`; the Release app was forced to this staging simulation through the production preset override `baseball-live-kr.backend-production-base-url=http://127.0.0.1:17361`, preserving the shipped redesigned SwiftUI stack while avoiding fabricated production-live evidence. Production import is recorded as a later follow-up, not part of this completion gate.

Simulation source:
- Endpoint: `http://127.0.0.1:17361/v1/games/today`
- Live count: 1
- Live game id: `20260705LTHH0`
- Statuses: `live`
- Visible app proof: `evidence/perf-sentinel/staging-live-simulation-screenshot.png` shows the Release app rendering the simulated LIVE game (롯데 12, 한화 9, 7회말, TEST).
- App: Release `BaseballLiveKR.app`
- Trace artifacts: ignored `artifacts/perf-sentinel/<surface>/`

Metric: exported Animation Hitches duration sum from `hitches-frame-lifetimes` table. Gate: staging sentinel average must not regress above the Phase 4 post-fix average from `evidence/perf-postfix/comparison.md`.

| Surface | Phase 4 post-fix avg | Sentinel avg | Delta vs Phase 4 | Gate |
|---------|----------------------|--------------|------------------|------|
| Menubar popover open | 25974.24 ms | 9303.43 ms | -16670.81 ms | PASS |
| TodayGames during live polling | 26193.92 ms | 9363.11 ms | -16830.81 ms | PASS |
| GameDetail live game | 24237.04 ms | 9251.25 ms | -14985.79 ms | PASS |

Supporting files:
- `evidence/perf-sentinel/menubar-popover.md`
- `evidence/perf-sentinel/today-games-live-polling.md`
- `evidence/perf-sentinel/game-detail-live.md`
- `evidence/perf-sentinel/sentinel-automation-transcript.json`
- `evidence/perf-sentinel/sentinel-duration-sums.json`
- `evidence/perf-sentinel/hitch-duration-summary.json`
- `evidence/perf-sentinel/staging-live-simulation-screenshot.png`
