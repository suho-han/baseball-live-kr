#!/usr/bin/env bash
set -euo pipefail

# Sparkle 업데이트 흐름을 실제로 돌려보기 위한 로컬 테스트 하네스.
# 로컬 HTTP 서버가 "현재 빌드보다 한 단계 높은" 테스트 appcast를 서빙하고,
# 앱을 -sparkleTestFeedURL 런치 아규먼트와 함께 실행해 그 피드를 바라보게 한다.
# 실제 GitHub 릴리즈 채널에는 영향이 없다.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-$ROOT_DIR/.build/macos-dmg/BaseballLiveKR.app}"
DMG_PATH="${DMG_PATH:-$(ls -t "$ROOT_DIR"/.build/transfer/BaseballLiveKR-*-macOS.dmg 2>/dev/null | head -1 || true)}"
TEST_DIR="${TEST_DIR:-$ROOT_DIR/.build/sparkle-test}"
PORT="${PORT:-8899}"
TEST_VERSION="${TEST_VERSION:-0.1.2}"
SPARKLE_TOOLS_DIR="${SPARKLE_TOOLS_DIR:-$ROOT_DIR/.build/sparkle-cli/bin}"
SERVER_LOG="$TEST_DIR/http-server.log"

if [[ ! -d "$APP_PATH" ]]; then
  printf 'Missing app bundle: %s\n' "$APP_PATH" >&2
  printf 'Package it first: ./scripts/package-macos-dmg.sh\n' >&2
  exit 1
fi

if [[ -z "$DMG_PATH" || ! -f "$DMG_PATH" ]]; then
  printf 'No packaged DMG found under .build/transfer.\n' >&2
  printf 'Package it first: ./scripts/package-macos-dmg.sh\n' >&2
  exit 1
fi

if [[ ! -x "$SPARKLE_TOOLS_DIR/sign_update" ]]; then
  printf 'Sparkle sign_update not found at %s\n' "$SPARKLE_TOOLS_DIR" >&2
  printf 'See docs/dev.md Sparkle section for tool setup.\n' >&2
  exit 1
fi

APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
TEST_BUILD=$((APP_BUILD + 1))

SIGNATURE_OUTPUT="$("$SPARKLE_TOOLS_DIR/sign_update" "$DMG_PATH")"
ED_SIGNATURE="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
SIGNATURE_LENGTH="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')"

if [[ -z "$ED_SIGNATURE" || -z "$SIGNATURE_LENGTH" ]]; then
  printf 'Failed to parse sign_update output: %s\n' "$SIGNATURE_OUTPUT" >&2
  exit 1
fi

mkdir -p "$TEST_DIR"
DMG_FILENAME="$(basename "$DMG_PATH")"
cp -f "$DMG_PATH" "$TEST_DIR/$DMG_FILENAME"

cat > "$TEST_DIR/appcast-test.xml" <<XML
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>Baseball LIVE KR 테스트 피드</title>
        <item>
            <title>Baseball LIVE KR $TEST_VERSION (테스트)</title>
            <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S %z")</pubDate>
            <sparkle:version>$TEST_BUILD</sparkle:version>
            <sparkle:shortVersionString>$TEST_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <enclosure url="http://127.0.0.1:$PORT/$DMG_FILENAME" sparkle:edSignature="$ED_SIGNATURE" length="$SIGNATURE_LENGTH" type="application/x-apple-diskimage"/>
        </item>
    </channel>
</rss>
XML

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$TEST_DIR" > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT INT TERM

FEED_READY=0
for _ in {1..20}; do
  if curl -fsS "http://127.0.0.1:$PORT/appcast-test.xml" >/dev/null 2>&1; then
    FEED_READY=1
    break
  fi
  sleep 0.5
done

if [[ "$FEED_READY" != 1 ]]; then
  printf 'Local test feed did not start on port %s. Log:\n' "$PORT" >&2
  tail -5 "$SERVER_LOG" >&2 || true
  exit 1
fi

printf '테스트 피드:  http://127.0.0.1:%s/appcast-test.xml\n' "$PORT"
printf '실행 앱:      %s (현재 %s 빌드 %s)\n' "$APP_PATH" "$APP_VERSION" "$APP_BUILD"
printf '광고 버전:    %s (빌드 %s) — 동일 DMG를 재사용합니다\n' "$TEST_VERSION" "$TEST_BUILD"
printf '서버 로그:    %s\n' "$SERVER_LOG"
printf '\n앱이 뜨면: 설정 > 업데이트 > 업데이트 확인 (또는 Sparkle 자동 확인 프롬프트 허용)\n'
printf '업데이트 대화상자에서 설치를 누르면 로컬 DMG를 받아 설치하고 앱을 재시작합니다.\n'
printf '테스트 종료는 Ctrl+C (로컬 서버가 내려갑니다).\n\n'

open -n "$APP_PATH" --args -sparkleTestFeedURL "http://127.0.0.1:$PORT/appcast-test.xml"

wait "$SERVER_PID"
