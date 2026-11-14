#!/usr/bin/env bash
# Checks that an APK carries the Sheikh's Al-Fatiha recording (R3) exactly:
# the Flutter asset assets/audio/al-fatiha-tafsir-r3.mp3 must be in the APK,
# byte-identical to the original (SHA-256), stored uncompressed, and the
# package ID unchanged. Since C-31 every build ships it.
#
# Usage: tool/check_apk_audio.sh [path/to/app.apk]   (default: app-debug.apk)
set -euo pipefail
cd "$(dirname "$0")/.."

APK="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
PKG=com.example.sheekhcali
SHA=3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f
BYTES=12587299
ENTRY=assets/flutter_assets/assets/audio/al-fatiha-tafsir-r3.mp3

inside=$(unzip -p "$APK" "$ENTRY" | sha256sum | cut -d' ' -f1)
[[ "$inside" == "$SHA" ]] || { echo "FAIL: $APK does not hold the original R3 ($inside)" >&2; exit 1; }
listing=$(unzip -v "$APK" "$ENTRY")
grep -Eq "^ *$BYTES +Stored +$BYTES " <<<"$listing" || { echo "FAIL: recording is compressed" >&2; exit 1; }
AAPT2=$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/aapt2 | sort -V | tail -1)
pkg=$("$AAPT2" dump packagename "$APK")
[[ "$pkg" == "$PKG" ]] || { echo "FAIL: unexpected package $pkg" >&2; exit 1; }
echo "OK: $APK"
echo "  size:    $(stat -c %s "$APK") bytes, sha256 $(sha256sum "$APK" | cut -d' ' -f1)"
echo "  package: $pkg"
echo "  R3:      $ENTRY, stored uncompressed, sha256 $inside"
