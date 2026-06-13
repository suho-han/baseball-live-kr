#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${ROOT_DIR}/backend-spike/logs/backend.pid"
PORT="${PORT:-3000}"

if [[ -f "${PID_FILE}" ]]; then
  PID="$(cat "${PID_FILE}")"
  if [[ -n "${PID}" ]] && kill -0 "${PID}" 2>/dev/null; then
    kill "${PID}"
    rm -f "${PID_FILE}"
    echo "backend stopped: pid ${PID}"
    exit 0
  fi
  rm -f "${PID_FILE}"
fi

PIDS="$(lsof -ti "tcp:${PORT}" || true)"
if [[ -n "${PIDS}" ]]; then
  kill ${PIDS}
  echo "backend stopped on port ${PORT}: ${PIDS}"
else
  echo "backend is not running on port ${PORT}"
fi
