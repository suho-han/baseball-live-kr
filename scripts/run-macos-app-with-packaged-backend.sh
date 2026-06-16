#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/.build/kbo-live-backend-macos"
APP_PATH="${ROOT_DIR}/.xcode/DerivedData/Build/Products/Debug/KboLive.app"
PORT="${PORT:-3000}"
FORCE_RESTART="${FORCE_RESTART:-0}"
PID_FILE="${BACKEND_DIR}/backend.pid"
LOG_FILE="${BACKEND_DIR}/backend.log"

if [[ ! -x "${BACKEND_DIR}/run-backend.command" ]]; then
  "${ROOT_DIR}/scripts/package-backend-macos.sh"
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "macOS app bundle not found: ${APP_PATH}" >&2
  echo "Build it first with: xcodebuild -project KboLiveApp.xcodeproj -scheme KboLivemacOS -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build" >&2
  exit 1
fi

if lsof -ti "tcp:${PORT}" >/dev/null; then
  if [[ "${FORCE_RESTART}" == "1" ]]; then
    echo "backend already listening on port ${PORT}; restarting because FORCE_RESTART=1"
    kill $(lsof -ti "tcp:${PORT}") 2>/dev/null || true
    sleep 0.3
  else
    echo "backend already listening on port ${PORT}"
    echo "set FORCE_RESTART=1 to restart it with the current environment"
  fi
fi

if ! lsof -ti "tcp:${PORT}" >/dev/null; then
  PORT="${PORT}" "${BACKEND_DIR}/run-backend.command" > "${LOG_FILE}" 2>&1 &
  echo "$!" > "${PID_FILE}"
  echo "backend started on port ${PORT}"
  echo "pid: $(cat "${PID_FILE}")"
  echo "log: ${LOG_FILE}"
fi

launchctl setenv KBO_LIVE_BASE_URL "http://127.0.0.1:${PORT}"
open -n "${APP_PATH}"

echo "app launched with KBO_LIVE_BASE_URL=http://127.0.0.1:${PORT}"
echo "stop backend: kill \$(cat ${PID_FILE})"
