# TodayGames during live polling — Release Baseline Summary

Generated: 2026-07-05T20:35:55

Production API live snapshot: date=20260705 live_count=2 live_ids=20260705LTKT0, 20260705SSSK0

Capture constraints:
- Build configuration: Release (`xcodebuild -scheme BaseballLiveKRmacOS -configuration Release ... build`).
- LaunchServices app launch with `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`; favorite team forced to `LT` only to route the UI to a live game participant.
- Heavy `.trace` bundles are intentionally ignored under `artifacts/perf-baseline/`.
- Each run used a 10s xctrace capture attached to `BaseballLiveKR`.
- TodayGames sample intent: Release main-window list/summary during live production polling with favorite team LT selected.

| Run | Animation trace | Hitch rows | Explicit hitch duration sum | Max explicit hitch | Time profile trace | Samples | Top app/framework symbols |
|-----|-----------------|------------|-----------------------------|--------------------|--------------------|---------|---------------------------|
| 1 | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r1-animation-hitches.trace` | 611 | 36960.22 ms (610 explicit rows) | 97.93 ms | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r1-time-profiler.trace` | 967 | static BaseballLiveKRmacOSApp.$main() ×1; AGGraphGetAttributeGraph ×1 |
| 2 | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r2-animation-hitches.trace` | 611 | 36693.88 ms (608 explicit rows) | 80.63 ms | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r2-time-profiler.trace` | 1047 | static BaseballLiveKRmacOSApp.$main() ×1 |
| 3 | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r3-animation-hitches.trace` | 614 | 34982.10 ms (611 explicit rows) | 81.06 ms | `artifacts/perf-baseline/today-games-live-polling/today-games-live-polling-release-production-live-r3-time-profiler.trace` | 1065 | URLSessionBaseballLiveKRAPIClient.fetchTodayGames(date:) ×2; closure #1 in JSONDecoder._decode&lt;A&gt;(_:from:) ×2; specialized GameDTO.init(from:) ×2; JSONDecoderImpl.unwrap&lt;A, B&gt;(_:as:for:_:) ×2; JSONDecoderImpl.KeyedContainer.decode&lt;A&gt;(_:forKey:) ×2 |

Notes:
- Earlier Debug/local-env traces were deleted and are not part of this accepted baseline.
