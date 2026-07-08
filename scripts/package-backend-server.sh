#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-spike"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/transfer}"
STAGING_DIR="${STAGING_DIR:-$ROOT_DIR/.build/remote-backend}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$OUT_DIR/baseball-live-kr-backend-server.tar.gz}"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to build the backend deploy artifact." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to build the backend deploy artifact." >&2
  exit 1
fi

cd "${BACKEND_DIR}"

if [[ ! -x "${BACKEND_DIR}/node_modules/.bin/tsc" || "${BACKEND_DIR}/package-lock.json" -nt "${BACKEND_DIR}/node_modules/.package-lock.json" ]]; then
  npm ci
fi

npm run build

rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}" "$(dirname "${ARCHIVE_PATH}")"

cp -R "${BACKEND_DIR}/dist" "${STAGING_DIR}/dist"
cp "${BACKEND_DIR}/package.json" "${STAGING_DIR}/package.json"
cp "${BACKEND_DIR}/package-lock.json" "${STAGING_DIR}/package-lock.json"

cat > "${STAGING_DIR}/run-backend.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js 22+ is required to run Baseball LIVE KR backend." >&2
  exit 1
fi

export NODE_ENV="${NODE_ENV:-production}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-17361}"

exec node "${DIR}/dist/src/index.js"
SCRIPT

chmod +x "${STAGING_DIR}/run-backend.command"
tar -czf "${ARCHIVE_PATH}" -C "${STAGING_DIR}" .

echo "Backend server archive: ${ARCHIVE_PATH}"
