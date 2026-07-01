# T5 final integration summary

Integration branch: `codex/baseball-live-kr-transition-integration`

Merged approved member work:

- T1/project-swift through `1c83b3f`
- T2/storage-runtime through `fc0e231`
- T3/backend-scripts-docs through `f4d8863`
- T4/rights-release-qa through `df90756`

Conflict resolutions:

- Removed T2 temporary `canImport(KboLiveCore)` fallbacks after T1 renamed packages/modules to `BaseballLiveKRCore`, `BaseballLiveKRDesignSystem`, and `BaseballLiveKRFeatures`.
- Kept T1's generated `BaseballLiveKR.xcodeproj` and discarded D's old `KboLiveApp.xcodeproj` cleanup as integration-obsolete evidence.
- Kept T3 backend/package naming while preserving T1 project/scheme names.
- Re-ran `xcodegen generate`; generated project now excludes `TeamLogos`, `TeamWordmarks`, and `TeamBrandAssets` release resources from app targets.

T5 residual fixes:

- `scripts/kbo-live.sh` now clears `BASEBALL_LIVE_KR_BASE_URL` before opening the app.
- `backend-spike/README.md` points Swift fixture docs at `Packages/BaseballLiveKRCore`.
- `backend-spike/tests/contract.test.ts` reads the renamed Swift contract fixture path.
- `BaseballLiveKR.xcodeproj/project.pbxproj` was regenerated from `project.yml` to remove stale official team PNG resource references.

Residual legacy-name search:

- Only `KBO_LIVE_BASE_URL` migration compatibility references remain in `BaseballLiveKREnvironment.swift` and its migration tests.
- Source official asset archives/manifests remain in the repository, but `project.yml` excludes them from generated app targets and `verify-release-assets.sh` passed against the built macOS app.

Verification summary:

- `swift test --package-path Packages/BaseballLiveKRCore`: passed, 55 tests.
- `swift test --package-path Packages/BaseballLiveKRDesignSystem`: passed, 5 tests.
- `swift test --package-path Packages/BaseballLiveKRFeatures`: passed, 27 tests.
- `npm --prefix backend-spike ci`: passed.
- `npm --prefix backend-spike test`: passed, 25 files / 91 tests.
- `npm --prefix backend-spike run build`: passed.
- `xcodegen generate`: passed.
- `xcodebuild -project BaseballLiveKR.xcodeproj -list`: passed with BaseballLiveKR schemes.
- `xcodebuild` macOS Debug build: passed.
- `xcodebuild` iOS simulator Debug build: passed.
- `scripts/package-backend-macos.sh`: passed.
- packaged backend `/health` on port 17389: passed.
- `./scripts/verify-release-assets.sh .xcode/DerivedData-macOS/Build/Products/Debug/BaseballLiveKR.app`: passed.
- `bash -n` on touched release/helper scripts: passed.
- `git diff --check`: passed before evidence summary.
