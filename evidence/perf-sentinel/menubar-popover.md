# Menubar Popover Sentinel — Staging Live Simulation

- Goal: G007
- Build: Release `BaseballLiveKR.app`
- Data source: local staging simulation via packaged backend, `KBO_USE_TEST_LIVE_GAME=1`, with the production preset overridden to `http://127.0.0.1:17361`
- Live evidence: `/v1/games/today` returned one live game, `20260705LTHH0`; screenshot shows LIVE 롯데 12 / 한화 9, 7회말, TEST
- Surface: menubar popover open / menu bar extra available while app was attached
- Trace location: `artifacts/perf-sentinel/menubar-popover/`

| Run | Animation Hitches sum | Hitch frames | Max frame duration | Time Profiler trace |
|-----|------------------------|--------------|--------------------|---------------------|
| 1 | 9429.39 ms | 198 | 64.61 ms | `menubar-popover-time-profiler-run1.trace` |
| 2 | 9232.84 ms | 194 | 64.22 ms | `menubar-popover-time-profiler-run2.trace` |
| 3 | 9248.07 ms | 195 | 80.63 ms | `menubar-popover-time-profiler-run3.trace` |

Average Animation Hitches sum: **9303.43 ms**.

Gate: PASS. The sentinel average is below the Phase 4 post-fix bar of 25974.24 ms.
