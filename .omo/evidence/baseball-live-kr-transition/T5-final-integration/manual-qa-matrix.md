# T5 manual QA matrix

| Check | Command or artifact | Result |
| --- | --- | --- |
| Integration branch status | `git status --short --branch` | Only T5 residual fixes and ignored verification outputs before staging. |
| Project generation | `xcodegen generate` | Passed; wrote `BaseballLiveKR.xcodeproj`. |
| Scheme inventory | `xcodebuild -project BaseballLiveKR.xcodeproj -list` | Passed; schemes are `BaseballLiveKRiOS`, `BaseballLiveKRmacOS`, `BaseballLiveKRWidgetExtension`. |
| Swift packages | Core, DesignSystem, Features `swift test` | Passed: 55, 5, and 27 tests. |
| Backend package | `npm ci`, `npm test`, `npm run build` | Passed; backend tests report 91 tests across 25 files. |
| macOS app build | `xcodebuild ... BaseballLiveKRmacOS ... build` | Passed; produced `BaseballLiveKR.app`. |
| iOS app build | `xcodebuild ... BaseballLiveKRiOS ... build` | Passed; includes widget dependency. |
| Backend packaging | `scripts/package-backend-macos.sh` | Passed; output `.build/baseball-live-kr-backend-macos`. |
| Backend runtime | packaged `run-backend.command`, curl `/health` | Passed on `127.0.0.1:17389`; process cleaned up. |
| Release asset gate | `verify-release-assets.sh` against built macOS app | Passed; no official visual asset filenames found. |
| Default verifier zero roots | `verify-release-assets.sh` with no default roots present | Expected exit 2; classified as adversarial zero-inspection guard. |
| Residual legacy names | focused `rg` search | Only old env key migration compatibility references remain. |
| Whitespace | `git diff --check` | Passed. |

Manual conclusion: integrated product builds and tests as Baseball LIVE KR. Remaining legacy strings are intentional migration compatibility or source KBO data terminology, not product/package/project names.
