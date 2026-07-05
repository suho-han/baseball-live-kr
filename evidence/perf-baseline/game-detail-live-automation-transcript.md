# GameDetail Live Automation Transcript

Surface: native macOS game detail window
Build: Release
Data source: `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`
Favorite team: `LT` to select live game `20260705LTKT0`.

Automation:

```applescript
tell application "System Events" to tell process "BaseballLiveKR"
  set frontmost to true
  click button 3 of scroll area 1 of group 1 of window "Baseball LIVE KR"
end tell
```

Accessibility proof after opening detail is recorded verbatim in `game-detail-live-ui-state.txt` and includes:

```text
진행중
LIVE · 7회초 · 2사
롯데
KT
경기 ID
20260705LTKT0
```

Evidence:
- `xcrun xctrace record --template 'Animation Hitches' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- `xcrun xctrace record --template 'Time Profiler' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- Trace bundle refs are listed in `game-detail-live.md`.
