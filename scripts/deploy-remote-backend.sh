#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEPLOY_ENV="${DEPLOY_ENV:-production}"
case "${DEPLOY_ENV}" in
  production|staging) ;;
  *)
    echo "DEPLOY_ENV must be 'production' or 'staging' (got '${DEPLOY_ENV}')." >&2
    exit 1
    ;;
esac

if [[ "${DEPLOY_ENV}" == "staging" ]]; then
  LOCAL_SECRET_FILE="${LOCAL_SECRET_FILE:-$ROOT_DIR/.connect/backend-deploy-staging.env}"
else
  LOCAL_SECRET_FILE="${LOCAL_SECRET_FILE:-$ROOT_DIR/.connect/backend-deploy.env}"
fi

if [[ -f "${LOCAL_SECRET_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${LOCAL_SECRET_FILE}"
  set +a
elif [[ "${DEPLOY_ENV}" == "staging" && "${DRY_RUN:-0}" == "1" ]]; then
  echo "DRY_RUN: ${LOCAL_SECRET_FILE} not found; continuing with environment values only." >&2
elif [[ "${DEPLOY_ENV}" == "staging" ]]; then
  echo "Staging deploy config not found: ${LOCAL_SECRET_FILE}" >&2
  echo "Create it with the staging values (keep real values out of tracked files):" >&2
  echo "  SSH_TARGET=user@staging-host" >&2
  echo "  # optional overrides: SSH_PORT, REMOTE_DIR, SERVICE_NAME, PORT, HOST, HEALTH_URL" >&2
  exit 1
fi

BACKEND_DIR="${ROOT_DIR}/backend-spike"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/transfer}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$OUT_DIR/baseball-live-kr-backend-server.tar.gz}"
SSH_TARGET="${SSH_TARGET:-}"
SSH_PORT="${SSH_PORT:-22}"
NODE_ENV="${NODE_ENV:-production}"
if [[ "${DEPLOY_ENV}" == "staging" ]]; then
  REMOTE_DIR="${REMOTE_DIR:-/home/suhohan/baseball-live-kr-backend-staging}"
  SERVICE_NAME="${SERVICE_NAME:-baseball-live-kr-backend-staging}"
  PORT="${PORT:-17362}"
else
  REMOTE_DIR="${REMOTE_DIR:-/home/suhohan/baseball-live-kr-backend}"
  SERVICE_NAME="${SERVICE_NAME:-baseball-live-kr-backend}"
  PORT="${PORT:-17361}"
fi
HOST="${HOST:-0.0.0.0}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:${PORT}/v1/health}"
DRY_RUN="${DRY_RUN:-0}"

if [[ -z "${SSH_TARGET}" ]]; then
  echo "SSH_TARGET is required. Set it in the environment or ${LOCAL_SECRET_FILE}." >&2
  exit 1
fi

run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

remote_sh() {
  local script="$1"

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '+ ssh -p %q %q %q\n' "${SSH_PORT}" "${SSH_TARGET}" "${script}"
    return 0
  fi

  ssh -p "${SSH_PORT}" "${SSH_TARGET}" "${script}"
}

OUT_DIR="${OUT_DIR}" ARCHIVE_PATH="${ARCHIVE_PATH}" "${ROOT_DIR}/scripts/package-backend-server.sh"

printf 'Deploying backend archive %s to %s:%s (env: %s)\n' "${ARCHIVE_PATH}" "${SSH_TARGET}" "${REMOTE_DIR}" "${DEPLOY_ENV}"

remote_sh "mkdir -p '${REMOTE_DIR}'"
run scp -P "${SSH_PORT}" "${ARCHIVE_PATH}" "${SSH_TARGET}:${REMOTE_DIR}/baseball-live-kr-backend-server.tar.gz"
remote_sh "cd '${REMOTE_DIR}' && tar -xzf baseball-live-kr-backend-server.tar.gz && npm ci --omit=dev && chmod +x run-backend.command"

remote_sh "mkdir -p ~/.config/systemd/user && cat > ~/.config/systemd/user/${SERVICE_NAME}.service <<'SERVICE'
[Unit]
Description=Baseball LIVE KR backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${REMOTE_DIR}
Environment=NODE_ENV=${NODE_ENV}
Environment=HOST=${HOST}
Environment=PORT=${PORT}
ExecStart=${REMOTE_DIR}/run-backend.command
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
SERVICE
systemctl --user daemon-reload
systemctl --user enable '${SERVICE_NAME}.service'
systemctl --user restart '${SERVICE_NAME}.service'"

printf 'Running remote backend health smoke: %s\n' "${HEALTH_URL}"
remote_sh "for i in {1..30}; do if curl -fsS --max-time 2 '${HEALTH_URL}'; then exit 0; fi; sleep 1; done; systemctl --user status '${SERVICE_NAME}.service' --no-pager || true; journalctl --user -u '${SERVICE_NAME}.service' -n 120 --no-pager || true; exit 1"

cat <<EOF

Remote backend deployed (env: ${DEPLOY_ENV}).

Service:
  systemctl --user status ${SERVICE_NAME}.service

Logs:
  journalctl --user -u ${SERVICE_NAME}.service -f

Health:
  ${HEALTH_URL}
EOF
