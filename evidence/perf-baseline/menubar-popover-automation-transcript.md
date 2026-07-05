# Menubar Popover Automation Transcript

Surface: native macOS MenuBarExtra popover
Build: Release
Data source: `BASEBALL_LIVE_KR_BASE_URL=https://api.baseball-live.kro.kr`

Automation:

```applescript
tell application "System Events" to tell process "BaseballLiveKR"
  click menu bar item 1 of menu bar 2
end tell
```

Evidence:
- `xcrun xctrace record --template 'Animation Hitches' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- `xcrun xctrace record --template 'Time Profiler' --attach <BaseballLiveKR pid> --time-limit 10s` succeeded for runs 1-3.
- Trace bundle refs are listed in `menubar-popover.md`.
- Run 1 is the cold popover-open sample after Release app launch; runs 2-3 are warm popover-open samples in the same Release process.
