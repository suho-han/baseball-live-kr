#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.xcode/DerivedData}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_PATH="${APP_PATH:-$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/BaseballLiveKR.app}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/transfer}"
STAGING_DIR="${STAGING_DIR:-$ROOT_DIR/.build/macos-dmg}"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.build/macos-dmg-work}"
VERSION="${VERSION:-0.1.0}"
VOLUME_NAME="${VOLUME_NAME:-Baseball LIVE KR}"
DMG_PATH="${DMG_PATH:-$OUT_DIR/BaseballLiveKR-$VERSION-macOS.dmg}"
RW_DMG_PATH="$WORK_DIR/BaseballLiveKR-$VERSION-macOS-rw.dmg"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PATH="$BACKGROUND_DIR/dmg-background.png"
BACKGROUND_SCRIPT="$WORK_DIR/dmg-background.swift"

require_tool() {
  local tool_name="$1"
  local install_hint="$2"

  if ! command -v "$tool_name" >/dev/null 2>&1; then
    printf '%s is required to create the macOS DMG layout.\n' "$tool_name" >&2
    printf '%s\n' "$install_hint" >&2
    exit 1
  fi
}

find_setfile() {
  if command -v SetFile >/dev/null 2>&1; then
    command -v SetFile
    return 0
  fi

  xcrun -f SetFile 2>/dev/null || true
}

mount_path_from_attach_output() {
  awk 'index($0, "/Volumes/") {print substr($0, index($0, "/Volumes/"))}' | tail -n 1
}

generate_background() {
  cat > "$BACKGROUND_SCRIPT" <<'SWIFT'
import AppKit
import Foundation

let outputPath = CommandLine.arguments[1]
let canvas = NSSize(width: 720, height: 420)
let image = NSImage(size: canvas)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func stroke(_ path: NSBezierPath, color strokeColor: NSColor, width: CGFloat) {
    strokeColor.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func fill(_ path: NSBezierPath, color fillColor: NSColor) {
    fillColor.setFill()
    path.fill()
}

image.lockFocus()

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 286, y: 230))
arrow.line(to: NSPoint(x: 434, y: 230))
stroke(arrow, color: color(36, 118, 255, 0.95), width: 15)

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 434, y: 230))
arrowHead.line(to: NSPoint(x: 406, y: 208))
arrowHead.move(to: NSPoint(x: 434, y: 230))
arrowHead.line(to: NSPoint(x: 406, y: 252))
stroke(arrowHead, color: color(36, 118, 255, 0.95), width: 15)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render DMG background")
}

try png.write(to: URL(fileURLWithPath: outputPath))
SWIFT

  swift "$BACKGROUND_SCRIPT" "$BACKGROUND_PATH"
}

if [[ ! -d "$APP_PATH" ]]; then
  printf 'Missing macOS app bundle: %s\n' "$APP_PATH" >&2
  printf 'Build it first with: xcodebuild -project BaseballLiveKR.xcodeproj -scheme BaseballLiveKRmacOS -configuration %s -destination "platform=macOS" -derivedDataPath .xcode/DerivedData build\n' "$CONFIGURATION" >&2
  exit 1
fi

require_tool hdiutil 'hdiutil ships with macOS. Run this script on macOS.'
require_tool osascript 'osascript ships with macOS. Run this script on macOS with Finder available.'
require_tool swift 'swift is required to render the DMG background. Install Xcode Command Line Tools with: xcode-select --install'

SETFILE_BIN="$(find_setfile)"

rm -rf "$STAGING_DIR" "$WORK_DIR" "$DMG_PATH" "$DMG_PATH.sha256"
mkdir -p "$BACKGROUND_DIR" "$WORK_DIR" "$OUT_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/BaseballLiveKR.app"

# Re-sign the staged copy ad-hoc so quarantine on the user's Mac shows the
# standard "Open Anyway" path instead of an unrecoverable "damaged" error.
STAGED_APP="$STAGING_DIR/BaseballLiveKR.app"
xattr -cr "$STAGED_APP"
codesign --force --sign - "$STAGED_APP"
codesign --verify --strict --deep "$STAGED_APP"

ln -s /Applications "$STAGING_DIR/Applications"
generate_background

if [[ -n "$SETFILE_BIN" ]]; then
  "$SETFILE_BIN" -a V "$BACKGROUND_DIR" || true
else
  printf 'SetFile was not found; continuing without hiding .background in Finder.\n' >&2
fi

hdiutil create \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -format UDRW \
  -srcfolder "$STAGING_DIR" \
  "$RW_DMG_PATH" >/dev/null

attach_output="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG_PATH")"
mount_path="$(printf '%s\n' "$attach_output" | mount_path_from_attach_output)"

if [[ -z "$mount_path" || ! -d "$mount_path" ]]; then
  printf 'Unable to mount writable DMG for layout.\n' >&2
  printf '%s\n' "$attach_output" >&2
  exit 1
fi

layout_volume_name="$(basename "$mount_path")"

cleanup_mount() {
  hdiutil detach "$mount_path" >/dev/null 2>&1 || true
}
trap cleanup_mount EXIT

if [[ -n "$SETFILE_BIN" ]]; then
  "$SETFILE_BIN" -a V "$mount_path/.background" || true
fi

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$layout_volume_name"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 840, 540}
    set viewOptions to icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set background picture of viewOptions to (POSIX file "$mount_path/.background/dmg-background.png" as alias)
    set position of item "BaseballLiveKR.app" of container window to {180, 210}
    set position of item "Applications" of container window to {540, 210}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

bless --folder "$mount_path" --openfolder "$mount_path" >/dev/null 2>&1 || true
sync
hdiutil detach "$mount_path" >/dev/null
trap - EXIT

hdiutil convert "$RW_DMG_PATH" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o \
  "$DMG_PATH" >/dev/null

rm -f "$RW_DMG_PATH"

DMG_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
printf '%s  %s\n' "$DMG_SHA256" "$(basename "$DMG_PATH")" > "$DMG_PATH.sha256"

printf 'Packaged macOS DMG: %s\n' "$DMG_PATH"
printf 'SHA-256: %s\n' "$DMG_SHA256"
printf 'Signing: ad-hoc (Gatekeeper warning expected until notarization)\n'
