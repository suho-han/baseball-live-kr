# Menubar popover open — Release Baseline Summary

Generated: 2026-07-05T20:35:37

Production API live snapshot: date=20260705 live_count=2 live_ids=20260705LTKT0, 20260705SSSK0

Capture constraints:
- Build configuration: Release (`xcodebuild -scheme BaseballLiveKRmacOS -configuration Release ... build`).
- LaunchServices app launch with `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`; favorite team forced to `LT` only to route the UI to a live game participant.
- Heavy `.trace` bundles are intentionally ignored under `artifacts/perf-baseline/`.
- Each run used a 10s xctrace capture attached to `BaseballLiveKR`.
- Menubar sample intent: run 1 cold popover open after app launch; runs 2-3 warm popover opens in same Release process.

| Run | Animation trace | Hitch rows | Explicit hitch duration sum | Max explicit hitch | Time profile trace | Samples | Top app/framework symbols |
|-----|-----------------|------------|-----------------------------|--------------------|--------------------|---------|---------------------------|
| 1 | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r1-animation-hitches.trace` | 615 | 33132.93 ms (612 explicit rows) | 80.64 ms | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r1-time-profiler.trace` | 1624 | static BaseballLiveKRmacOSApp.$main() ×1 |
| 2 | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r2-animation-hitches.trace` | 611 | 34203.44 ms (605 explicit rows) | 81.12 ms | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r2-time-profiler.trace` | 1625 | protocol witness for KeyedDecodingContainerProtocol.decode(_:forKey:) in conformance JSONDecoderImpl.KeyedContainer&lt;A&gt; ×4; specialized GameDTO.init(from:) ×4; closure #1 in JSONDecoder._decode&lt;A&gt;(_:from:) ×2; JSONDecoderImpl.unwrap&lt;A, B&gt;(_:as:for:_:) ×2; protocol witness for KeyedDecodingContainerProtocol.decode&lt;A&gt;(_:forKey:) in conformance JSONDecoderImpl.KeyedContainer&lt;A&gt; ×2 |
| 3 | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r3-animation-hitches.trace` | 613 | 35964.54 ms (611 explicit rows) | 81.29 ms | `artifacts/perf-baseline/menubar-popover/menubar-popover-release-production-live-r3-time-profiler.trace` | 1480 | static BaseballLiveKRmacOSApp.$main() ×1; +[_SwiftUILayerDelegate actionForLayer:forKey:] ×1 |

Notes:
- Earlier Debug/local-env traces were deleted and are not part of this accepted baseline.
