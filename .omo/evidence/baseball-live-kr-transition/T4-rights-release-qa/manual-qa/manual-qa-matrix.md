# T4 Manual QA Matrix

Scope: rights-release-qa for official visual asset removal, UI fallback replacement, release archive inspection, and notarization readiness.

| Scenario | Command or artifact | Expected | Result |
| --- | --- | --- | --- |
| RED baseline official assets exist in source checkout | `baseline/official-asset-files.txt` | TeamBrandAssets, TeamLogos, and TeamWordmarks present before T4 changes | PASS: baseline captured official visual asset risk |
| RED baseline official asset loaders exist | `baseline/asset-risk-search.txt` | Runtime loaders and resource declarations are visible before T4 changes | PASS: baseline captured loader/resource risk |
| Source runtime loaders removed | `green/no-runtime-official-image-loaders.txt` | 0 matches for `NSImage(named:)`, `UIImage(named:)`, teamID bundle URL loaders, `logoImage`, `loadPlatformImage` | PASS: file has 0 lines |
| Built macOS app excludes official assets | `manual-qa/built-app-official-asset-find.txt` | 0 matches for TeamBrandAssets, TeamWordmarks, TeamLogos, logo, wordmark, emblem, mascot, and team-ID PNG filenames | PASS: file has 0 lines |
| Built macOS app asset verifier | `green/verify-release-assets-built-app.txt` | `No official visual asset filenames found in release/staged artifacts.` | PASS |
| Visual UI fallback | `manual-qa/macos-launch-screenshot.png` | Team visuals render as text initials in self-owned colored shapes, not official marks | PASS: screenshot shows initials badges for standings and favorite-team prompt |
| Korean/CJK visible UI | `manual-qa/macos-launch-screenshot.png` | No visible Korean text clipping or awkward line break in the captured app window | PASS |
| Archive member adversarial probe | `adversarial/misleading_success_archive_output.txt` | Verifier fails nonzero when a tar archive contains `TeamLogos/HH.png` | PASS: exit code 1 |
| Filesystem adversarial probe | `adversarial/misleading_success_output.txt` | Verifier fails nonzero when a staged app contains `TeamLogos/HH.png` | PASS: exit code 1 |
| Stale team state | `adversarial/stale_state-main-team-json.txt`, `adversarial/stale_state-main-guide.txt` | Main team state binds D to this thread and cwd | PASS |
| Dirty worktree preservation | `baseline/dirty-worktree-before.txt`, `adversarial/dirty_worktree-current.txt` | Pre-existing unrelated dirty files remain unstaged/unreverted | PASS |
| Long command handling | `adversarial/hung_or_long_commands.txt`, `green/xcodebuild-macos-debug.txt` | Long macOS build is observed to completion and succeeds | PASS |
| Cleanup | `manual-qa/cleanup-receipt.txt` | No leftover app process, injected probe directories removed, fake app/archive artifacts absent, screenshot retained, unrelated dirty work preserved | PASS |

Notes:
- `KboLiveApp.xcodeproj` edits in this worktree are local baseline-project evidence only. The durable generated-project exclusion is `project.yml`, which now excludes `TeamLogos/**`, `TeamWordmarks/**`, and `TeamBrandAssets/**`.
- T3 owns package output naming. T4 added a separate verifier script and did not change `scripts/package-macmini-runtime.sh`.
