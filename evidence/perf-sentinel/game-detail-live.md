# GameDetail Live Sentinel — Staging Live Simulation

- Goal: G007
- Build: Release `BaseballLiveKR.app`
- Data source: local staging simulation via packaged backend, `KBO_USE_TEST_LIVE_GAME=1`, with the production preset overridden to `http://127.0.0.1:17361`
- Live evidence: `/v1/games/today` returned one live game, `20260705LTHH0`; screenshot shows LIVE 롯데 12 / 한화 9, 7회말, TEST
- Surface: representative live/detail path for the staging live simulation
- Trace location: `artifacts/perf-sentinel/game-detail-live/`

| Run | Animation Hitches sum | Hitch frames | Max frame duration | Time Profiler trace |
|-----|------------------------|--------------|--------------------|---------------------|
| 1 | 9311.79 ms | 196 | 49.24 ms | `game-detail-live-time-profiler-run1.trace` |
| 2 | 9169.01 ms | 193 | 64.74 ms | `game-detail-live-time-profiler-run2.trace` |
| 3 | 9272.96 ms | 195 | 64.94 ms | `game-detail-live-time-profiler-run3.trace` |

Average Animation Hitches sum: **9251.25 ms**.

Gate: PASS. The sentinel average is below the Phase 4 post-fix bar of 24237.04 ms.
