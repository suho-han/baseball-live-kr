# T5 cleanup receipt

- Packaged backend health-check process was killed and waited after `/health` returned `ok`.
- No active `swift test`, `swift-testing`, `xcodebuild`, `XCBBuildService`, `node dist/src/index`, or `run-backend.command` process remained at cleanup probe time.
- Build artifacts remain ignored under `.build/`, `.xcode/`, package `.build/`, `backend-spike/dist/`, and `backend-spike/node_modules/`.
- T5 evidence is under `.omo/evidence/baseball-live-kr-transition/T5-final-integration/` and must be force-added because `.omo` is ignored.
- Root worktree pre-existing dirt was not touched; integration happened in a separate clean worktree to avoid the untracked `baseball-live-kr-deployment-plan.md` conflict.
