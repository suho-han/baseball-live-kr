# T4 Implementation Review

Reviewed files:

- `project.yml`
- `KboLiveApp.xcodeproj/project.pbxproj`
- `KboLiveApp/Shared/AppSettingsView.swift`
- `Packages/KboLiveDesignSystem/Sources/KboLiveDesignSystem/Components/TeamBadgeView.swift`
- `Packages/KboLiveFeatures/Sources/KboLiveFeatures/TodayGames/TodayGamesView.swift`
- `scripts/verify-release-assets.sh`
- `PROJECT_CONTEXT/macos-release-operations.md`

Findings:

- Official runtime image loaders were removed from the edited SwiftUI surfaces. The replacement UI uses `Text` initials inside owned rounded color shapes.
- `project.yml` is the durable source of truth for generated project resources and now excludes all three official asset directories: `TeamLogos/**`, `TeamWordmarks/**`, and `TeamBrandAssets/**`.
- The checked-in baseline `KboLiveApp.xcodeproj` was also cleaned so this worktree can build and inspect a clean app bundle. Per leader coordination, that generated-project edit is integration-obsolete because T1 replaces it with `BaseballLiveKR.xcodeproj`; the equivalent durable exclusion is the `project.yml` change.
- `scripts/verify-release-assets.sh` checks staged/built filesystem paths and archive member names for official visual asset filenames. It fails on injected filesystem and tar archive probes.
- Notarization readiness is documented as a credentialed procedure rather than claimed as executed.

Slop and safety coverage:

- No `as any`, `@ts-ignore`, or `@ts-expect-error` style suppressions were introduced.
- No official team mark was replaced by a static mock image or screenshot.
- No package output naming was changed in T4; that remains C/backend-scripts-docs ownership.
- `remove-ai-slops` was not invoked as a separate cleanup skill because this was a narrow T4 implementation, but the diff was checked for common slop patterns: dead image-loader fallback paths, stale references, fake success-only verification, and unchecked archive contents.
- `programming` skill is not applicable by its trigger list because the edited code is Swift and shell/docs, not `.py`, `.rs`, `.ts`, `.tsx`, or `.go`; the Swift package tests and macOS build were used instead.

Verification summary:

- `swift test --package-path Packages/KboLiveDesignSystem`: PASS
- `swift test --package-path Packages/KboLiveFeatures`: PASS
- `xcodebuild -project KboLiveApp.xcodeproj -scheme KboLivemacOS -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build`: PASS
- `./scripts/verify-release-assets.sh .xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`: PASS
- `git diff --check`: PASS
