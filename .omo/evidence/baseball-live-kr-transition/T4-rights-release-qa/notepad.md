# T4 Notepad

Use this file as the compact handoff index for T4 evidence.

Primary artifacts:

- RED baseline: `baseline/official-asset-files.txt`
- RED search: `baseline/asset-risk-search.txt`
- Implementation review: `implementation-review.md`
- Manual QA matrix: `manual-qa/manual-qa-matrix.md`
- Built app official asset search: `manual-qa/built-app-official-asset-find.txt`
- Built app tree: `manual-qa/built-app-tree.txt`
- macOS screenshot: `manual-qa/macos-launch-screenshot.png`
- macOS launch log: `manual-qa/macos-launch.log`
- Release verifier result: `green/verify-release-assets-built-app.txt`
- Swift tests: `green/swift-test-design-system.txt`, `green/swift-test-features.txt`
- macOS build: `green/xcodebuild-macos-debug.txt`
- Adversarial probes: `adversarial/`
- Cleanup receipt: `manual-qa/cleanup-receipt.txt`

Integration notes:

- T1 owns the generated `BaseballLiveKR.xcodeproj` replacement. T4's durable generated-project input is `project.yml`, which excludes official asset directories.
- C owns package output naming. T4's release gate is the standalone `scripts/verify-release-assets.sh`.
