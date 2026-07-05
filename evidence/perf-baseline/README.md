# Performance Evidence

Heavy Instruments `.trace` bundles are stored under ignored `artifacts/perf-baseline/<surface>/` and are not committed. Commit only lightweight summaries here.

| Surface | Heavy Trace Directory | Summary File | Status |
|---------|-----------------------|--------------|--------|
| Menubar popover open | `artifacts/perf-baseline/menubar-popover/` | `menubar-popover.md` | baseline captured (Release, N=3, Animation Hitches + Time Profiler) |
| TodayGames during live polling | `artifacts/perf-baseline/today-games-live-polling/` | `today-games-live-polling.md` | baseline captured (Release, N=3, Animation Hitches + Time Profiler) |
| GameDetail during a live game | `artifacts/perf-baseline/game-detail-live/` | `game-detail-live.md` | baseline captured (Release, N=3, Animation Hitches + Time Profiler; UI proof in `game-detail-live-ui-state.txt`) |
