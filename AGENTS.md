# AGENTS.md

## Response Style

- Respond in the language requested by the user.
- Use plain filenames or repo-relative paths such as `Packages/BaseballLiveKRCore/Package.swift`.
- Do not use clickable local file links in responses for this repo.
- If the caller explicitly says the task is being handled through Discord, keep messages short, split long responses by section with `(1/N)` markers, and do not split code blocks across messages.

## Project Context

- Start with `CONTEXT/README.md`, then read the focused context file for the task.
- Keep `CONTEXT/` concise and factual; update existing notes when project direction or reproducibility assumptions change.
- `docs/dev.md` is the command reference for local development, validation, packaging, and backend operations.
- `README.md` is user-facing product documentation. Keep implementation and deployment details in `docs/dev.md` or `CONTEXT/`.

## Launch Helper

- Work from the repository root.
- For sessions that need full local write access, commits, project-local skill installs, or `.git`/`.agents` writes, launch with:

```bash
./scripts/codex-full-access.sh
```

- The helper wraps the repo-approved Codex flags. Prefer the script over duplicating the raw command.

## Build, Test, And Run

- Use `./scripts/baseball-live-kr.sh run`, `live`, `open`, `verify`, or `package` for the main app workflows.
- Use `./scripts/verify-local.sh` for full local verification. Use `SKIP_XCODE=1 ./scripts/verify-local.sh` when Xcode target builds are intentionally out of scope.
- Swift package checks live under:
  - `Packages/BaseballLiveKRCore`
  - `Packages/BaseballLiveKRDesignSystem`
  - `Packages/BaseballLiveKRFeatures`
- The Xcode project is generated from `project.yml`. If the project file is stale, regenerate it with the XcodeGen command documented in `docs/dev.md`.
- Do not silently change default endpoints, data sources, bundle settings, or validation behavior. Record meaningful changes in the relevant docs or context file.

## Backend Spike

- Backend prototype code lives in `backend-spike/`.
- Package commands are defined in `backend-spike/package.json`; use that file as the source of truth for npm scripts and runtime requirements.
- Common local checks are `npm test`, `npm run build`, and `npm run typecheck` from `backend-spike/`.
- Local backend start/stop helpers are `scripts/backend-start.sh` and `scripts/backend-stop.sh`.

## Deploy And Secrets

- Existing tracked docs may contain historical deploy examples; do not copy those values into `AGENTS.md` or add new/current secret deploy hosts, IP addresses, endpoint URLs, port numbers, SSH passwords, tokens, or credentials to tracked repo files.
- Keep local deploy host and port values in `.env.local`. The repo `.gitignore` ignores `.env.*`, so `.env.local` must stay untracked.
- Before remote backend deploys, source the local secret file in the shell that runs the deploy script:

```bash
set -a
source .env.local
set +a
./scripts/baseball-live-kr.sh deploy-backend
```

- `scripts/deploy-remote-backend.sh` is the current backend deploy implementation. Use its environment variables for deploy target, remote directory, bind host, service port, and health check URL; keep the values themselves in `.env.local`.
- Use `DRY_RUN=1 ./scripts/deploy-remote-backend.sh` only to inspect local command construction. Do not run SSH, Tailscale, remote deploys, or network probes unless the user explicitly requests them.
- If `.env.local` ever becomes tracked, run `git rm --cached -- .env.local` and keep the local file.
