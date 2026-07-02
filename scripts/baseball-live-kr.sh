#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.xcode/DerivedData}"

print_help() {
  cat <<'TEXT'
Baseball LIVE KR helper

Usage:
  ./scripts/baseball-live-kr.sh run      Build and open the macOS app with game data
  ./scripts/baseball-live-kr.sh live     Open the macOS app with a sample live game
  ./scripts/baseball-live-kr.sh open     Build and open only the macOS app
  ./scripts/baseball-live-kr.sh verify   Run local verification
  ./scripts/baseball-live-kr.sh package  Build the Mac mini test package
  ./scripts/baseball-live-kr.sh deploy-backend
                                Build and deploy the remote backend service

Environment:
  FORCE_RESTART=1   Restart the local game data process
  PORT=17361        Use another local port
TEXT
}

build_macos_app() {
  xcodebuild \
    -scheme BaseballLiveKRmacOS \
    -project "$ROOT_DIR/BaseballLiveKR.xcodeproj" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
}

command="${1:-help}"

case "$command" in
  run)
    build_macos_app
    "$ROOT_DIR/scripts/run-macos-app-with-packaged-backend.sh"
    ;;
  live)
    build_macos_app
    KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART="${FORCE_RESTART:-1}" "$ROOT_DIR/scripts/run-macos-app-with-packaged-backend.sh"
    ;;
  open)
    build_macos_app
    launchctl unsetenv BASEBALL_LIVE_KR_BASE_URL
    open -n "$DERIVED_DATA_PATH/Build/Products/Debug/BaseballLiveKR.app"
    ;;
  verify)
    "$ROOT_DIR/scripts/verify-local.sh"
    ;;
  package)
    build_macos_app
    "$ROOT_DIR/scripts/package-macmini-runtime.sh"
    ;;
  deploy-backend)
    "$ROOT_DIR/scripts/deploy-remote-backend.sh"
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    printf 'Unknown command: %s\n\n' "$command" >&2
    print_help >&2
    exit 2
    ;;
esac
