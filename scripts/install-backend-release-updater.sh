#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_SECRET_FILE="${LOCAL_SECRET_FILE:-$ROOT_DIR/.connect/backend-deploy.env}"

if [[ -f "${LOCAL_SECRET_FILE}" ]]; then
  set -a
  source "${LOCAL_SECRET_FILE}"
  set +a
fi

SSH_TARGET="${SSH_TARGET:-}"
SSH_PORT="${SSH_PORT:-22}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
RELEASE_ASSET_NAME="${RELEASE_ASSET_NAME:-baseball-live-kr-backend-server.tar.gz}"
REMOTE_INSTALL_ROOT="${REMOTE_INSTALL_ROOT:-/home/suhohan/baseball-live-kr-backend}"
SERVICE_NAME="${SERVICE_NAME:-baseball-live-kr-backend}"
PORT="${PORT:-17361}"
HOST="${HOST:-0.0.0.0}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:${PORT}/v1/health}"
CHECK_INTERVAL="${CHECK_INTERVAL:-5min}"
RUN_ON_INSTALL="${RUN_ON_INSTALL:-0}"
DRY_RUN="${DRY_RUN:-0}"

if [[ -z "${SSH_TARGET}" ]]; then
  echo "SSH_TARGET is required. Set it in the environment or ${LOCAL_SECRET_FILE}." >&2
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY}" ]]; then
  echo "GITHUB_REPOSITORY is required, for example owner/baseball-live-kr." >&2
  exit 1
fi

remote_sh() {
  local script="$1"

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '+ ssh -p %q %q %q\n' "${SSH_PORT}" "${SSH_TARGET}" "${script}"
    return 0
  fi

  ssh -p "${SSH_PORT}" "${SSH_TARGET}" "${script}"
}

copy_remote_file() {
  local source_path="$1"
  local target_path="$2"
  local mode="$3"

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '+ scp -P %q %q %q\n' "${SSH_PORT}" "${source_path}" "${SSH_TARGET}:${target_path}"
    printf '+ ssh -p %q %q %q\n' "${SSH_PORT}" "${SSH_TARGET}" "chmod ${mode} ${target_path}"
    return 0
  fi

  scp -P "${SSH_PORT}" "${source_path}" "${SSH_TARGET}:${target_path}"
  ssh -p "${SSH_PORT}" "${SSH_TARGET}" "chmod ${mode} ${target_path}"
}

remote_sh "mkdir -p ~/.local/bin ~/.config/baseball-live-kr ~/.config/systemd/user '${REMOTE_INSTALL_ROOT}' '${REMOTE_INSTALL_ROOT}/releases'"
copy_remote_file "${ROOT_DIR}/scripts/backend-release-update.sh" "~/.local/bin/baseball-live-kr-backend-release-update" "755"

remote_sh "cat > ~/.config/baseball-live-kr/backend-release.env <<'ENV'
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
RELEASE_ASSET_NAME=${RELEASE_ASSET_NAME}
INSTALL_ROOT=${REMOTE_INSTALL_ROOT}
SERVICE_NAME=${SERVICE_NAME}
PORT=${PORT}
HEALTH_URL=${HEALTH_URL}
ENV"

remote_sh "cat > ~/.config/systemd/user/${SERVICE_NAME}.service <<'SERVICE'
[Unit]
Description=Baseball LIVE KR backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${REMOTE_INSTALL_ROOT}/current
Environment=NODE_ENV=production
Environment=HOST=${HOST}
Environment=PORT=${PORT}
ExecStart=${REMOTE_INSTALL_ROOT}/current/run-backend.command
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
SERVICE"

remote_sh "cat > ~/.config/systemd/user/${SERVICE_NAME}-release-update.service <<'SERVICE'
[Unit]
Description=Deploy the latest Baseball LIVE KR backend GitHub release
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/baseball-live-kr-backend-release-update
SERVICE"

remote_sh "cat > ~/.config/systemd/user/${SERVICE_NAME}-release-update.timer <<'TIMER'
[Unit]
Description=Check GitHub Releases for Baseball LIVE KR backend updates

[Timer]
OnBootSec=2min
OnUnitActiveSec=${CHECK_INTERVAL}
RandomizedDelaySec=30s
Persistent=true

[Install]
WantedBy=timers.target
TIMER"

remote_sh "systemctl --user daemon-reload && systemctl --user enable '${SERVICE_NAME}.service' && systemctl --user enable --now '${SERVICE_NAME}-release-update.timer'"

if [[ "${RUN_ON_INSTALL}" == "1" ]]; then
  remote_sh "systemctl --user start '${SERVICE_NAME}-release-update.service'"
fi

cat <<EOF

GitHub Release updater installed.

Timer:
  systemctl --user status ${SERVICE_NAME}-release-update.timer

Run once:
  systemctl --user start ${SERVICE_NAME}-release-update.service

Logs:
  journalctl --user -u ${SERVICE_NAME}-release-update.service -u ${SERVICE_NAME}.service -f
EOF
