#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_TARGET="${SSH_TARGET:-suhohan@100.114.89.25}"
REMOTE_DIR="${REMOTE_DIR:-/Users/suhohan/Projects/kbo-live}"
PORT="${PORT:-3019}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/.build/transfer/kbo-live-macmini-runtime.tar.gz}"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  "$ROOT_DIR/scripts/package-macmini-runtime.sh"
fi

printf 'Uploading %s to %s:%s\n' "$ARCHIVE_PATH" "$SSH_TARGET" "$REMOTE_DIR"
ssh "$SSH_TARGET" "mkdir -p '$REMOTE_DIR'"
scp "$ARCHIVE_PATH" "$SSH_TARGET:$REMOTE_DIR/kbo-live-macmini-runtime.tar.gz"

ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && tar -xzf kbo-live-macmini-runtime.tar.gz && chmod +x scripts/run-macos-app-with-packaged-backend.sh .build/kbo-live-backend-macos/run-backend.command"

printf 'Running remote backend health smoke on port %s\n' "$PORT"
ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && PORT=$PORT .build/kbo-live-backend-macos/run-backend.command >/tmp/kbo-live-backend-$PORT.log 2>&1 & pid=\$!; for i in {1..20}; do if curl -fsS --max-time 1 http://127.0.0.1:$PORT/health; then kill \$pid; wait \$pid 2>/dev/null || true; exit 0; fi; sleep 0.25; done; cat /tmp/kbo-live-backend-$PORT.log; kill \$pid 2>/dev/null || true; exit 1"

cat <<EOF

Remote runtime deployed.

Run on Mac mini:
cd $REMOTE_DIR
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
EOF
