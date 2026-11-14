#!/usr/bin/env bash
# Puts a byte-identical copy of the Sheikh's Al-Fatiha recording (R3) where
# the app bundles it: assets/audio/al-fatiha-tafsir-r3.mp3 (pubspec.yaml).
# Every `flutter build apk` (debug and release) then contains it (owner
# decision C-31, 2026-11-14).
#
# The original in shiiq_mp3/ is only read: its size and SHA-256 are checked
# before copying, and the copy is checked after. The copy is git-ignored
# (*.mp3, T-16), like the original: run this once on each machine that
# builds the app.
set -euo pipefail
cd "$(dirname "$0")/../.."

SHA=3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f
BYTES=12587299
SRC="shiiq_mp3/003-الفاتحة 1-آخرها.mp3"
DEST=assets/audio/al-fatiha-tafsir-r3.mp3

check() { [[ -f "$1" && "$(stat -c %s "$1")" == "$BYTES" && "$(sha256sum "$1" | cut -d' ' -f1)" == "$SHA" ]]; }

if check "$DEST"; then echo "Already bundled and verified: $DEST"; exit 0; fi
check "$SRC" || { echo "Refusing: $SRC is missing or not the original R3" >&2; exit 1; }
mkdir -p "$(dirname "$DEST")"
cp "$SRC" "$DEST.part"
check "$DEST.part" || { rm -f "$DEST.part"; echo "Copy does not match" >&2; exit 1; }
mv "$DEST.part" "$DEST"
check "$SRC"
echo "Bundled: $DEST (sha256 $SHA, $BYTES bytes); original unchanged"
