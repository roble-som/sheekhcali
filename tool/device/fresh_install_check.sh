#!/usr/bin/env bash
# Fresh-install, OFFLINE acceptance check of an APK on an Android
# EMULATOR (Linux host with PipeWire), as a user would get it:
#
#   1. the app is uninstalled (no app data left) and the emulator goes
#      offline (airplane mode, Wi-Fi and mobile data off; checked);
#   2. the APK is installed with plain `adb install` (no recording pushed,
#      no developer script);
#   3. the app is opened from the launcher, the Quran card opens page 1,
#      and each Al-Fatiha ayah is tapped while ONLY the emulator's own audio
#      output is recorded; a rapid double tap and a long segment's end are
#      included;
#   4. the app is force-stopped and reopened (still offline) and an ayah is
#      tapped again; the unpacked copy must not be copied again;
#   5. tool/device/verify_heard_segments.py checks, from the capture alone,
#      that every tap was audible, came from the start of that ayah's
#      segment in the original recording, and that playback stopped at the
#      end of a segment.
# The network is restored at the end. The original recording is only read
# (hash checked before and after).
#
# Usage: PYTHON=/path/to/python-with-numpy-and-miniaudio \
#   tool/device/fresh_install_check.sh APK [emulator-serial] [out-dir]
set -euo pipefail
cd "$(dirname "$0")/../.."

APK="$1"
SERIAL="${2:-emulator-5554}"
OUT="${3:-build/fresh_install_check}"
PY="${PYTHON:-python3}"
PKG=com.example.sheekhcali
SHA=3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f
SRC="shiiq_mp3/003-الفاتحة 1-آخرها.mp3"
UI=(python3 -I tool/device/android_ui.py "$SERIAL")
A=(adb -s "$SERIAL")
mkdir -p "$OUT"
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$OUT/steps.txt"; }
: >"$OUT/steps.txt"

[[ "$(sha256sum "$SRC" | cut -d' ' -f1)" == "$SHA" ]] || { echo "original changed?" >&2; exit 1; }
log "original R3 sha256 before: $SHA"
log "APK: $APK ($(stat -c %s "$APK") bytes, sha256 $(sha256sum "$APK" | cut -d' ' -f1))"

# ---- 1. clean device, offline ------------------------------------------------
"${A[@]}" uninstall "$PKG" >/dev/null 2>&1 || true
[[ -z "$("${A[@]}" shell pm path "$PKG" 2>/dev/null)" ]] || { echo "still installed" >&2; exit 1; }
log "uninstalled: no app, no app data"

restore_network() {
  "${A[@]}" shell cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
  "${A[@]}" shell svc wifi enable >/dev/null 2>&1 || true
  "${A[@]}" shell svc data enable >/dev/null 2>&1 || true
}
"${A[@]}" shell cmd connectivity airplane-mode enable
"${A[@]}" shell svc wifi disable
"${A[@]}" shell svc data disable
sleep 4
if "${A[@]}" shell ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
  echo "Network still reachable: not an offline test." >&2; restore_network; exit 1
fi
active=$("${A[@]}" shell dumpsys connectivity | grep -m1 'Active default network' | tr -d '\r')
log "offline: airplane mode on, Wi-Fi and data off, ping fails ($active)"
# Android's Live Caption overlay can cover the ayahs while audio plays and
# swallow taps (seen on the emulator): keep it off during the test.
"${A[@]}" shell settings put secure odi_captions_enabled 0 2>/dev/null || true

# ---- 2. plain install ----------------------------------------------------------
"${A[@]}" install "$APK" >/dev/null
log "installed with adb install (nothing else copied to the device)"
# Android 13+ asks for notification permission on first playback; granting it
# here only keeps that dialog from covering the screen. Playback works without.
"${A[@]}" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
# App storage can be inspected only in a debuggable (debug) build. A release
# build is checked by what it plays; the app itself refuses any copy whose
# SHA-256 differs from the original.
DEBUGGABLE=false
"${A[@]}" shell run-as "$PKG" true >/dev/null 2>&1 && DEBUGGABLE=true
if $DEBUGGABLE; then
  if "${A[@]}" shell run-as "$PKG" ls files/dev-media >/dev/null 2>&1; then
    echo "unexpected: recording present before first launch" >&2; exit 1
  fi
  log "before first launch: no recording in app storage"
else
  log "release build: app storage not readable (run-as needs a debuggable app); checked by audio"
fi

# ---- capture of the emulator's own output only ----------------------------------
SINK=sheekh_emulator_capture
pw-link -o | grep -q '^qemu-system-x86_64:output_FL$' || { echo "No emulator audio" >&2; exit 1; }
pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=$SINK node.description=\"Sheekh emulator capture\" media.class=Audio/Sink object.linger=true audio.position=[FL FR] }" >/dev/null
sink_id=""
for _ in $(seq 1 20); do
  sink_id=$(pw-dump | python3 -c '
import json, sys
for o in json.load(sys.stdin):
    p = (o.get("info") or {}).get("props") or {}
    if p.get("node.name") == sys.argv[1]:
        print(o["id"]); break
' "$SINK")
  [[ -n "$sink_id" ]] && break
  sleep 0.2
done
rec=""
cleanup() {
  [[ -n "$rec" ]] && kill -INT "$rec" 2>/dev/null || true
  [[ -n "$sink_id" ]] && pw-cli destroy "$sink_id" >/dev/null 2>&1 || true
  restore_network
}
trap cleanup EXIT
sleep 0.5
pw-link qemu-system-x86_64:output_FL "$SINK:playback_FL"
pw-link qemu-system-x86_64:output_FR "$SINK:playback_FR"
for _ in $(seq 1 15); do
  now=$("${A[@]}" shell cmd media_session volume --stream 3 --get 2>/dev/null | sed -n 's/.*volume is \([0-9]*\).*/\1/p')
  [[ -z "$now" || "$now" -ge 11 ]] && break
  "${A[@]}" shell input keyevent KEYCODE_VOLUME_UP; sleep 0.5
done

wav="$OUT/emulator_output.wav"
wav_start=$(date +%s%3N)
pw-record --target "$SINK" -P '{ stream.capture.sink = true }' --rate 16000 --channels 1 "$wav" &
rec=$!
echo "$wav_start" >"$OUT/wav_start_ms.txt"
sleep 1
sources=$(pw-link -l | awk '/^pw-record:/ {r=1; next} /^[^ ]/ {r=0} r && /\|<-/ {print $2}')
if [[ -z "$sources" ]] || grep -qv "^$SINK:monitor_" <<<"$sources"; then
  echo "Recorder not connected to the emulator capture sink only" >&2; exit 1
fi
log "recording only: $(tr '\n' ' ' <<<"$sources")"

# ---- 3. first launch, page 1, taps ----------------------------------------------
"${A[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
"${UI[@]}" tap 'Quran\..*' 40 >/dev/null
log "opened the Quran card"
"${UI[@]}" wait 'Tafsir of Al-Fatiha · Sheikh Calinuur' 60
log "player ready (recording unpacked and verified by the app)"
"${UI[@]}" shot "$OUT/01_page1_ready.png"
if $DEBUGGABLE; then
  "${A[@]}" shell run-as "$PKG" ls -l --full-time files/dev-media | tee -a "$OUT/steps.txt"
  device_sha=$("${A[@]}" shell run-as "$PKG" sha256sum "files/dev-media/$SHA.mp3" | cut -d' ' -f1)
  [[ "$device_sha" == "$SHA" ]] || { echo "device copy differs: $device_sha" >&2; exit 1; }
  log "device copy sha256: $device_sha (equal to the original)"
  mtime_before=$("${A[@]}" shell run-as "$PKG" stat -c %Y "files/dev-media/$SHA.mp3" | tr -d '\r')
fi

silence_from=$(date +%s%3N); sleep 3; silence_to=$(date +%s%3N)
taps="["
digits=(x ١ ٢ ٣ ٤ ٥ ٦ ٧)
# Ayah number markers, located once while the screen is idle (the
# accessibility dump is unreliable while playback redraws the player).
declare -A at
locate_ayahs() {
  for n in 1 2 3 4 5 6 7; do at[$n]=$("${UI[@]}" find "Ayah ${digits[$n]}" 20); done
  log "ayah markers at: $(for n in 1 2 3 4 5 6 7; do printf '%s=(%s) ' "$n" "${at[$n]}"; done)"
}
# The tap time is taken just BEFORE the tap is sent, so "time since the
# tap" is never underestimated.
tap_at() { local t; t=$(date +%s%3N); "${A[@]}" shell input tap ${at[$1]}; echo "$t"; }
locate_ayahs
tap_ayah() {  # ayah, listen seconds, label, extra json
  local t
  t=$(tap_at "$1")
  log "tapped ayah $1 ($3) at $t"
  sleep 2.5
  "${UI[@]}" shot "$OUT/tap_${1}_${3// /_}.png"
  sleep "$(( $2 - 2 ))"
  taps+="{\"ayah\": $1, \"tapMs\": $t, \"label\": \"$3\"${4:-}},"
}
# The first tap after a launch loads the player (cold start), so it gets
# longer to be heard.
tap_ayah 1 16 "first launch, cold"
tap_ayah 2 8 "first launch"
tap_ayah 3 24 "segment end" ', "expectStop": true'
# "Play Recitation + Tafsir" on ayah 4 (player paused after ayah 3): long
# press, then the sheet row. The Sheikh's reading of ayah 4, then his
# explanation of it.
"${A[@]}" shell input swipe ${at[4]} ${at[4]} 900
sleep 1.5
t=$("${UI[@]}" tap 'Play.?Recitation \+ Tafsir' 15)
log "Play Recitation + Tafsir on ayah 4 at $t"
sleep 12
taps+="{\"ayah\": 4, \"tapMs\": $t, \"label\": \"recitation + tafsir\", \"withReading\": true},"
for n in 4 5 6 7; do tap_ayah "$n" 8 "first launch"; done
# Rapid switching: ayah 2, then ayah 6 at once. Ayah 6 must win.
t2=$(tap_at 2)
t6=$(tap_at 6)
log "rapid: ayah 2 at $t2, ayah 6 at $t6"
sleep 8
taps+="{\"ayah\": 6, \"tapMs\": $t6, \"label\": \"rapid 2 then 6\"},"

# ---- 4. force-stop and restart, still offline ------------------------------------
"${A[@]}" shell am force-stop "$PKG"
sleep 2
log "force-stopped"
"${A[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
"${UI[@]}" tap 'Quran\..*' 40 >/dev/null
"${UI[@]}" wait 'Tafsir of Al-Fatiha · Sheikh Calinuur' 60
log "restarted offline: player ready"
locate_ayahs
tap_ayah 5 16 "after restart, cold"
if $DEBUGGABLE; then
  mtime_after=$("${A[@]}" shell run-as "$PKG" stat -c %Y "files/dev-media/$SHA.mp3" | tr -d '\r')
  [[ "$mtime_before" == "$mtime_after" ]] || { echo "recording was copied again" >&2; exit 1; }
  leftovers=$("${A[@]}" shell run-as "$PKG" ls files/dev-media | grep -c '\.part' || true)
  log "after restart: same file reused (mtime $mtime_after), no partial files ($leftovers)"
fi
"${A[@]}" shell am force-stop "$PKG"
sleep 1

kill -INT "$rec"; wait "$rec" 2>/dev/null || true; rec=""
taps="${taps%,}]"
echo "{\"silence\": [$silence_from, $silence_to], \"taps\": $taps}" >"$OUT/taps.json"

"$PY" -I tool/device/verify_heard_segments.py --wav "$wav" --wav-start-ms "$wav_start" \
  --taps "$OUT/taps.json" --mp3 "$SRC" \
  --candidates assets/content/alignments/al-fatiha-tafsir-r3.candidates.json \
  --json-out "$OUT/heard_segments.json" | tee -a "$OUT/steps.txt"
status=${PIPESTATUS[0]}

[[ "$(sha256sum "$SRC" | cut -d' ' -f1)" == "$SHA" ]]
log "original R3 sha256 after: $SHA (unchanged)"
exit "$status"
