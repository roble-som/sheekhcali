#!/usr/bin/env bash
# Installs the original R3 recording on a connected Android device/emulator for
# a DEBUG build (testing only, C-26). The file is copied, never modified; its
# SHA-256 is checked on this computer before and on the device after.
#
# Usage: tool/device/install_r3.sh [device-serial]
set -euo pipefail

cd "$(dirname "$0")/../.."
SERIAL="${1:-}"
ADB=(adb)
[[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

PKG=com.example.sheekhcali
SHA=3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f
SRC="shiiq_mp3/003-الفاتحة 1-آخرها.mp3"
DEST="files/dev-media/$SHA.mp3"

actual=$(sha256sum "$SRC" | cut -d' ' -f1)
if [[ "$actual" != "$SHA" ]]; then
  echo "Refusing: $SRC is not the original recording (sha256 $actual)." >&2
  exit 1
fi

if ! "${ADB[@]}" shell pm path "$PKG" >/dev/null 2>&1; then
  echo "App not installed: building and installing the debug APK first."
  flutter build apk --debug
  "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk
fi

if [[ "$("${ADB[@]}" shell run-as "$PKG" sha256sum "$DEST" 2>/dev/null | cut -d' ' -f1)" == "$SHA" ]]; then
  echo "Recording already installed and verified."
  exit 0
fi

"${ADB[@]}" push "$SRC" /data/local/tmp/r3.mp3 >/dev/null
"${ADB[@]}" shell run-as "$PKG" mkdir -p files/dev-media
"${ADB[@]}" shell run-as "$PKG" cp /data/local/tmp/r3.mp3 "$DEST"
"${ADB[@]}" shell rm /data/local/tmp/r3.mp3
on_device=$("${ADB[@]}" shell run-as "$PKG" sha256sum "$DEST" | cut -d' ' -f1)
if [[ "$on_device" != "$SHA" ]]; then
  echo "Copy on the device does not match (sha256 $on_device)." >&2
  exit 1
fi
# Lets the playback notification appear without a prompt (Android 13+).
"${ADB[@]}" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
echo "Installed and verified on the device: $SHA"
