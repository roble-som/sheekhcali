#!/usr/bin/env bash
# Builds the TESTING APK that carries the Sheikh's original Al-Fatiha
# recording (R3), so it plays offline right after a plain install on the
# owner's own test devices: no adb, no script, no network.
#
# Owner decision 2026-11-13 (C-26 as extended): testing APKs only. Never
# publish or distribute this file. The default `flutter build apk` contains
# no recording.
#
# What it checks:
#   * the source file is the original (size and SHA-256) before building;
#   * the APK holds it byte-identical, stored uncompressed;
#   * the package ID is unchanged.
#
# Usage: tool/build_testing_apk.sh            (debug mode, the default)
#        tool/build_testing_apk.sh profile    (smaller and faster; still a
#                                              debug-signed testing APK)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-debug}"
case "$MODE" in debug|profile) ;; *) echo "mode must be debug or profile" >&2; exit 2;; esac

PKG=com.example.sheekhcali
SHA=3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f
BYTES=12587299
SRC="shiiq_mp3/003-الفاتحة 1-آخرها.mp3"

[[ -f "$SRC" ]] || { echo "Missing original recording: $SRC" >&2; exit 1; }
[[ "$(stat -c %s "$SRC")" == "$BYTES" ]] || { echo "Refusing: $SRC has the wrong size" >&2; exit 1; }
[[ "$(sha256sum "$SRC" | cut -d' ' -f1)" == "$SHA" ]] || { echo "Refusing: $SRC is not the original R3" >&2; exit 1; }

flutter build apk "--$MODE" --dart-define=SHEEKH_TESTING_AUDIO=true

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')
APK="build/app/outputs/flutter-apk/app-$MODE.apk"
OUT="build/app/outputs/flutter-apk/sheekhcali-$VERSION-$MODE-TESTING-with-R3-NOT-FOR-DISTRIBUTION.apk"
cp "$APK" "$OUT"

ENTRY="assets/testing-audio/$SHA.mp3"
inside=$(unzip -p "$OUT" "$ENTRY" | sha256sum | cut -d' ' -f1)
[[ "$inside" == "$SHA" ]] || { echo "APK does not hold the original ($inside)" >&2; exit 1; }
listing=$(unzip -v "$OUT" "$ENTRY")
grep -Eq "^ *$BYTES +Stored +$BYTES " <<<"$listing" || { echo "Recording is compressed in the APK" >&2; exit 1; }

AAPT2=$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/aapt2 | sort -V | tail -1)
pkg=$("$AAPT2" dump packagename "$OUT")
[[ "$pkg" == "$PKG" ]] || { echo "Unexpected package $pkg" >&2; exit 1; }

# The original is untouched.
[[ "$(sha256sum "$SRC" | cut -d' ' -f1)" == "$SHA" ]]

echo "TESTING APK (debug-signed, not for distribution): $OUT"
echo "  size:    $(stat -c %s "$OUT") bytes"
echo "  sha256:  $(sha256sum "$OUT" | cut -d' ' -f1)"
echo "  package: $pkg"
echo "  R3 inside: $ENTRY, stored uncompressed, sha256 $inside"
