#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.xcode/DerivedData}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_PATH="${APP_PATH:-$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/BaseballLiveKR.app}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/transfer}"
STAGING_DIR="${STAGING_DIR:-$ROOT_DIR/.build/macos-dmg}"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.build/macos-dmg-work}"
VERSION="${VERSION:-}"
VOLUME_NAME="${VOLUME_NAME:-Baseball LIVE KR}"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PATH="$BACKGROUND_DIR/dmg-background.png"
BACKGROUND_SCRIPT="$WORK_DIR/dmg-background.swift"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SPARKLE_TOOLS_DIR="${SPARKLE_TOOLS_DIR:-$ROOT_DIR/.build/sparkle-cli/bin}"
RELEASE_DOWNLOAD_URL_PREFIX="${RELEASE_DOWNLOAD_URL_PREFIX:-https://github.com/suho-han/baseball-live-kr/releases/download}"

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

submit_for_notarization() {
  local artifact_path="$1"
  local description="$2"

  printf 'Submitting %s for notarization: %s\n' "$description" "$artifact_path"
  xcrun notarytool submit "$artifact_path" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
}

staple_and_validate() {
  local artifact_path="$1"

  xcrun stapler staple "$artifact_path"
  xcrun stapler validate "$artifact_path"
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

if [[ -n "$NOTARY_PROFILE" && -z "$SIGN_IDENTITY" ]]; then
  printf 'NOTARY_PROFILE requires SIGN_IDENTITY so the app is Developer ID signed before notarization.\n' >&2
  exit 1
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  require_tool xcrun 'xcrun ships with Xcode. Install Xcode and configure notarytool credentials first.'
fi

SETFILE_BIN="$(find_setfile)"

rm -rf "$STAGING_DIR" "$WORK_DIR"
mkdir -p "$BACKGROUND_DIR" "$WORK_DIR" "$OUT_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/BaseballLiveKR.app"

STAGED_APP="$STAGING_DIR/BaseballLiveKR.app"
xattr -cr "$STAGED_APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$STAGED_APP/Contents/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$STAGED_APP/Contents/Info.plist")"
DMG_PATH="${DMG_PATH:-$OUT_DIR/BaseballLiveKR-$VERSION-macOS.dmg}"
RW_DMG_PATH="$WORK_DIR/BaseballLiveKR-$VERSION-macOS-rw.dmg"
APP_ZIP_PATH="$WORK_DIR/BaseballLiveKR-$VERSION-macOS-app.zip"
rm -f "$DMG_PATH" "$DMG_PATH.sha256"

if [[ -n "$SIGN_IDENTITY" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$STAGED_APP"
else
  # Re-sign the staged copy ad-hoc so quarantine on the user's Mac shows the
  # standard "Open Anyway" path instead of an unrecoverable "damaged" error.
  codesign --force --sign - "$STAGED_APP"
fi

codesign --verify --strict --deep "$STAGED_APP"

if [[ -n "$NOTARY_PROFILE" ]]; then
  ditto -c -k --keepParent "$STAGED_APP" "$APP_ZIP_PATH"
  submit_for_notarization "$APP_ZIP_PATH" 'app bundle zip'
  staple_and_validate "$STAGED_APP"
  spctl --assess --type execute --verbose=4 "$STAGED_APP"
fi

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

if ! osascript <<APPLESCRIPT
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
then
  printf 'Finder icon layout failed (automation permission or Finder busy); continuing with default DMG layout.\n' >&2
  printf 'Re-run this script from a terminal with Finder automation permission to arrange the icons.\n' >&2
fi

bless --folder "$mount_path" --openfolder "$mount_path" >/dev/null 2>&1 || true
sync
hdiutil detach "$mount_path" >/dev/null 2>&1 || hdiutil detach "$mount_path" -force >/dev/null 2>&1
trap - EXIT

hdiutil convert "$RW_DMG_PATH" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o \
  "$DMG_PATH" >/dev/null

rm -f "$RW_DMG_PATH"

DMG_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
printf '%s  %s\n' "$DMG_SHA256" "$(basename "$DMG_PATH")" > "$DMG_PATH.sha256"

if [[ -n "$NOTARY_PROFILE" ]]; then
  submit_for_notarization "$DMG_PATH" 'DMG'
  staple_and_validate "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
fi

if [[ -n "${SPARKLE_SIGN_UPDATE:-}" ]]; then
  SPARKLE_SIGN_UPDATE_BIN="$SPARKLE_SIGN_UPDATE"
elif [[ -x "$SPARKLE_TOOLS_DIR/sign_update" ]]; then
  SPARKLE_SIGN_UPDATE_BIN="$SPARKLE_TOOLS_DIR/sign_update"
elif command -v sign_update >/dev/null 2>&1; then
  SPARKLE_SIGN_UPDATE_BIN="$(command -v sign_update)"
else
  printf 'Sparkle sign_update is required to sign the DMG and generate appcast.xml.\n' >&2
  printf 'Set SPARKLE_TOOLS_DIR to a directory containing sign_update (keychain EdDSA key required).\n' >&2
  exit 1
fi

SIGNATURE_OUTPUT="$("$SPARKLE_SIGN_UPDATE_BIN" "$DMG_PATH")"
ED_SIGNATURE="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
SIGNATURE_LENGTH="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')"

if [[ -z "$ED_SIGNATURE" || -z "$SIGNATURE_LENGTH" ]]; then
  printf 'Failed to parse sign_update output: %s\n' "$SIGNATURE_OUTPUT" >&2
  exit 1
fi

APPCAST_PATH="${APPCAST_PATH:-$OUT_DIR/appcast.xml}"
DOWNLOAD_URL="$RELEASE_DOWNLOAD_URL_PREFIX/v$VERSION/$(basename "$DMG_PATH")"

cat > "$APPCAST_PATH" <<XML
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
    <channel>
        <title>Baseball LIVE KR</title>
        <link>https://github.com/suho-han/baseball-live-kr/releases/latest/download/appcast.xml</link>
        <description>Baseball LIVE KR 자동 업데이트 피드</description>
        <language>ko</language>
        <item>
            <title>Baseball LIVE KR $VERSION</title>
            <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S %z")</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <enclosure url="$DOWNLOAD_URL" sparkle:edSignature="$ED_SIGNATURE" length="$SIGNATURE_LENGTH" type="application/x-apple-diskimage"/>
        </item>
    </channel>
</rss>
XML

printf 'Packaged macOS DMG: %s\n' "$DMG_PATH"
printf 'SHA-256: %s\n' "$DMG_SHA256"
if [[ -n "$SIGN_IDENTITY" ]]; then
  printf 'Signing: %s\n' "$SIGN_IDENTITY"
else
  printf 'Signing: ad-hoc (Gatekeeper warning expected until notarization)\n'
fi
if [[ -n "$NOTARY_PROFILE" ]]; then
  printf 'Notarization: stapled app and DMG using keychain profile %s\n' "$NOTARY_PROFILE"
else
  printf 'Notarization: skipped\n'
fi
printf 'Sparkle EdDSA: signed (%s bytes, sparkle:version %s)\n' "$SIGNATURE_LENGTH" "$BUILD_NUMBER"
printf 'Sparkle appcast: %s\n' "$APPCAST_PATH"
