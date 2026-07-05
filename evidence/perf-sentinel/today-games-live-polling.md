# TodayGames Live Polling Sentinel — Staging Live Simulation

- Goal: G007
- Build: Release `BaseballLiveKR.app`
- Data source: local staging simulation via packaged backend, `KBO_USE_TEST_LIVE_GAME=1`, with the production preset overridden to `http://127.0.0.1:17361`
- Live evidence: `/v1/games/today` returned one live game, `20260705LTHH0`; screenshot shows LIVE 롯데 12 / 한화 9, 7회말, TEST
- Surface: TodayGames list visible while polling the local live simulation
- Trace location: `artifacts/perf-sentinel/today-games-live-polling/`

| Run | Animation Hitches sum | Hitch frames | Max frame duration | Time Profiler trace |
|-----|------------------------|--------------|--------------------|---------------------|
| 1 | 9352.33 ms | 196 | 64.59 ms | `today-games-live-polling-time-profiler-run1.trace` |
| 2 | 9484.85 ms | 196 | 80.74 ms | `today-games-live-polling-time-profiler-run2.trace` |
| 3 | 9252.14 ms | 194 | 64.50 ms | `today-games-live-polling-time-profiler-run3.trace` |

Average Animation Hitches sum: **9363.11 ms**.

Gate: PASS. The sentinel average is below the Phase 4 post-fix bar of 26193.92 ms.
