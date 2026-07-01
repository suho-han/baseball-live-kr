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
- Excessive or useless tests: no new product tests were added; verification uses focused existing Swift package tests plus release artifact probes.
- Deletion-only tests: no tests were deleted or weakened.
- Tautological tests: the release verifier is checked against real negative probes that contain `TeamLogos/HH.png` in both filesystem and tar archive form, so it does not only assert its own success path.
- Implementation-mirroring tests: verifier probes inspect release/staged artifact paths and archive member names, not Swift implementation details or view internals.
- Unnecessary extraction/parsing/normalization: no new parsers or abstractions were introduced for UI fallback rendering; the only normalization is bounded path/name matching inside `scripts/verify-release-assets.sh` and whitespace cleanup in the captured xcodebuild evidence log.
- Overfit behavior: `scripts/verify-release-assets.sh` covers the official asset directory names, generic logo/wordmark/emblem/mascot terms, and current team-ID PNG names across directories and archives rather than a single built-app path.
- `remove-ai-slops` was not invoked as a separate cleanup skill because this was a narrow T4 implementation, but the diff was explicitly checked for dead image-loader fallback paths, stale references, fake success-only verification, unchecked archive contents, and the criteria above.
- `programming` skill is not applicable by its trigger list because the edited code is Swift and shell/docs, not `.py`, `.rs`, `.ts`, `.tsx`, or `.go`; the Swift package tests and macOS build were used instead.

Verification summary:

- `swift test --package-path Packages/KboLiveDesignSystem`: PASS
- `swift test --package-path Packages/KboLiveFeatures`: PASS
- `xcodebuild -project KboLiveApp.xcodeproj -scheme KboLivemacOS -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build`: PASS
- `./scripts/verify-release-assets.sh .xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`: PASS
- `git diff --check 43b4445^ 43b4445`: initially failed on trailing whitespace in `green/xcodebuild-macos-debug.txt`; this follow-up evidence-only commit normalizes that log.
- `git diff --check 43b4445^ HEAD`: PASS after follow-up normalization.
