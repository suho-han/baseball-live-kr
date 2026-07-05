# GameDetail during live game (20260705LTKT0) — Release Baseline Summary

Generated: 2026-07-05T20:36:14

Production API live snapshot: date=20260705 live_count=2 live_ids=20260705LTKT0, 20260705SSSK0

Capture constraints:
- Build configuration: Release (`xcodebuild -scheme BaseballLiveKRmacOS -configuration Release ... build`).
- LaunchServices app launch with `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`; favorite team forced to `LT` only to route the UI to a live game participant.
- Heavy `.trace` bundles are intentionally ignored under `artifacts/perf-baseline/`.
- Each run used a 10s xctrace capture attached to `BaseballLiveKR`.
- Detail proof: UI state file shows `진행중`, `LIVE · 6회초 · 2사`, teams `롯데`/`KT`, and game ID `20260705LTKT0` before accepted Release detail traces.

| Run | Animation trace | Hitch rows | Explicit hitch duration sum | Max explicit hitch | Time profile trace | Samples | Top app/framework symbols |
|-----|-----------------|------------|-----------------------------|--------------------|--------------------|---------|---------------------------|
| 1 | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r1-animation-hitches.trace` | 613 | 29132.02 ms (606 explicit rows) | 114.76 ms | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r1-time-profiler.trace` | 1227 | specialized GameDTO.init(from:) ×5; closure #2 in TodayGames.orderedGames(filter:preferredTeamID:) ×4; closure #1 in JSONDecoder._decode&lt;A&gt;(_:from:) ×2; JSONDecoderImpl.unwrap&lt;A, B&gt;(_:as:for:_:) ×2; protocol witness for KeyedDecodingContainerProtocol.decode&lt;A&gt;(_:forKey:) in conformance JSONDecoderImpl.KeyedContainer&lt;A&gt; ×2 |
| 2 | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r2-animation-hitches.trace` | 614 | 32007.57 ms (614 explicit rows) | 131.13 ms | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r2-time-profiler.trace` | 1231 | specialized GameDTO.init(from:) ×6; JSONDecoderImpl.unwrap&lt;A, B&gt;(_:as:for:_:) ×3; closure #1 in JSONDecoder._decode&lt;A&gt;(_:from:) ×2; closure #1 in closure #1 in LiveGamePollingService.streamTodayGames(date:) ×2; specialized TodayGamesResponseDTO.init(from:) ×2 |
| 3 | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r3-animation-hitches.trace` | 614 | 29218.29 ms (605 explicit rows) | 98.47 ms | `artifacts/perf-baseline/game-detail-live/game-detail-live-release-production-live-r3-time-profiler.trace` | 1238 | specialized GameDTO.init(from:) ×5; closure #2 in TodayGames.orderedGames(filter:preferredTeamID:) ×5; closure #1 in JSONDecoder._decode&lt;A&gt;(_:from:) ×2; protocol witness for KeyedDecodingContainerProtocol.decodeIfPresent(_:forKey:) in conformance JSONDecoderImpl.KeyedContainer&lt;A&gt; ×2; protocol witness for KeyedDecodingContainerProtocol.decode&lt;A&gt;(_:forKey:) in conformance JSONDecoderImpl.KeyedContainer&lt;A&gt; ×2 |

Notes:
- Earlier Debug/local-env traces were deleted and are not part of this accepted baseline.
