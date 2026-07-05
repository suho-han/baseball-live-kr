# TodayGames Live Polling Automation Transcript

Surface: native macOS main window / TodayGames live polling
Build: Release
Data source: `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`
Favorite team: `LT` to route the main surface toward a live participant.

Accessibility text captured before trace window:

```text
Baseball LIVE KR
2026.07.05 (일) · 20시 20분
오늘의 초점
L
롯데
응원팀 현황 · 대표 경기
응원팀 현황
L
롯데 자이언츠
리그 전체
진행 중 경기를 우선 정렬한 전체 경기 목록입니다.
필터
```

Evidence:
- Production API snapshot during summary generation: `live_count=2`, `20260705LTKT0`, `20260705SSSK0`.
- `xcrun xctrace record --template 'Animation Hitches' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- `xcrun xctrace record --template 'Time Profiler' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- Trace bundle refs are listed in `today-games-live-polling.md`.
