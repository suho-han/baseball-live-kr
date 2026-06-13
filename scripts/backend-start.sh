#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-spike"
LOG_DIR="${BACKEND_DIR}/logs"
PID_FILE="${LOG_DIR}/backend.pid"
PORT="${PORT:-3000}"

mkdir -p "${LOG_DIR}"

if lsof -ti "tcp:${PORT}" >/dev/null; then
  echo "backend already listening on port ${PORT}"
  exit 0
fi

cd "${BACKEND_DIR}"
PORT="${PORT}" nohup npm run dev > "${LOG_DIR}/backend.log" 2>&1 &
echo "$!" > "${PID_FILE}"

echo "backend started on port ${PORT}"
echo "pid: $(cat "${PID_FILE}")"
echo "log: ${LOG_DIR}/backend.log"
