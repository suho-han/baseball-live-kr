#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAPTURE_DATE="${1:-$(TZ=Asia/Seoul date +%Y%m%d)}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-30}"
ITERATIONS="${ITERATIONS:-480}"

cd "$ROOT_DIR/backend-spike"

npm run poll -- \
  --date "$CAPTURE_DATE" \
  --interval "$INTERVAL_SECONDS" \
  --iterations "$ITERATIONS" \
  --save-raw \
  --logs-dir "$ROOT_DIR/backend-spike/logs/polling/$CAPTURE_DATE" \
  --fixtures-dir "$ROOT_DIR/backend-spike/fixtures/live-$CAPTURE_DATE"
