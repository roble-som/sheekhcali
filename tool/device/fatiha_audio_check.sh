#!/usr/bin/env bash
# End-to-end check on a Linux host with an Android EMULATOR and PipeWire:
#   1. installs the original recording (hash-checked) for the debug app;
#   2. records what the emulator actually outputs (its own audio stream only);
#   3. runs integration_test/fatiha_ayah_tafsir_test.dart (taps every ayah);
#   4. checks with tool/device/verify_fatiha_audio.py that every tap was
#      audible and came from the expected point of the original recording.
# Fails if any step fails, including silence.
#
# Usage: PYTHON=/path/to/python-with-numpy-and-miniaudio \
#          tool/device/fatiha_audio_check.sh [emulator-serial] [out-dir]
set -euo pipefail

cd "$(dirname "$0")/../.."
SERIAL="${1:-emulator-5554}"
OUT="${2:-build/fatiha_audio_check}"
PY="${PYTHON:-python3}"
mkdir -p "$OUT"

tool/device/install_r3.sh "$SERIAL"

# Capture ONLY the emulator: a private virtual output ("null sink") that only
# the emulator's output ports are linked to (it keeps playing on the speakers
# too). The recorder listens to that sink's monitor, so a microphone can never
# be recorded; the links are checked before the test starts.
SINK=sheekh_emulator_capture
if ! pw-link -o | grep -q '^qemu-system-x86_64:output_FL$'; then
  echo "No emulator audio output found (is the emulator running with audio?)." >&2
  exit 1
fi
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
[[ -n "$sink_id" ]] || { echo "Could not create the capture sink." >&2; exit 1; }
rec=""
old_volume=""
cleanup() {
  [[ -n "$rec" ]] && kill -INT "$rec" 2>/dev/null || true
  pw-cli destroy "$sink_id" >/dev/null 2>&1 || true
  [[ -n "$old_volume" ]] && set_media_volume "$old_volume" || true
}
trap cleanup EXIT
sleep 0.5
pw-link qemu-system-x86_64:output_FL "$SINK:playback_FL"
pw-link qemu-system-x86_64:output_FR "$SINK:playback_FR"

# A clearly audible media volume for the test, restored afterwards. (The
# volume keys are used because "cmd media_session volume --set" is ignored on
# recent Android versions.)
media_volume() {
  adb -s "$SERIAL" shell cmd media_session volume --stream 3 --get 2>/dev/null \
    | sed -n 's/.*volume is \([0-9]*\).*/\1/p'
}
set_media_volume() {
  local want=$1 now key
  for _ in $(seq 1 30); do
    now=$(media_volume)
    [[ -z "$now" || "$now" -eq "$want" ]] && return 0
    key=KEYCODE_VOLUME_UP
    (( now > want )) && key=KEYCODE_VOLUME_DOWN
    adb -s "$SERIAL" shell input keyevent "$key"
    sleep 1
  done
}
old_volume=$(media_volume)
set_media_volume 11
echo "Emulator media volume: $old_volume -> $(media_volume) of 15"

# Device clock minus host clock (both in ms since the epoch).
host_before=$(date +%s%3N)
device_now=$(adb -s "$SERIAL" shell date +%s%3N | tr -d '\r')
host_after=$(date +%s%3N)
offset=$(( device_now - (host_before + host_after) / 2 ))

wav="$OUT/emulator_output.wav"
log="$OUT/integration_test.log"
wav_start=$(date +%s%3N)
echo "wav_start_ms=$wav_start device_offset_ms=$offset" >"$OUT/timing.txt"
pw-record --target "$SINK" -P '{ stream.capture.sink = true }' \
  --rate 16000 --channels 1 "$wav" &
rec=$!
sleep 1
# Every link into the recorder must come from the capture sink's monitor.
sources=$(pw-link -l | awk '/^pw-record:/ {r=1; next} /^[^ ]/ {r=0} r && /\|<-/ {print $2}')
if [[ -z "$sources" ]] || grep -qv "^$SINK:monitor_" <<<"$sources"; then
  echo "Recorder is not connected to the emulator capture sink only:" >&2
  echo "$sources" >&2
  kill -INT "$rec" 2>/dev/null || true
  wait "$rec" 2>/dev/null || true
  rm -f "$wav"
  exit 1
fi
echo "Recording only: $(tr '\n' ' ' <<<"$sources")"

set +e
flutter test integration_test/fatiha_ayah_tafsir_test.dart -d "$SERIAL" \
  >"$log" 2>&1
test_status=$?
set -e
sleep 1
kill -INT "$rec" 2>/dev/null || true
wait "$rec" 2>/dev/null || true
rec=""

grep -E "EVIDENCE|All tests passed|Some tests failed|Expected|Actual" "$log" || true
echo "integration test exit code: $test_status"

"$PY" -I tool/device/verify_fatiha_audio.py \
  --log "$log" --wav "$wav" --wav-start-ms "$wav_start" \
  --device-offset-ms "$offset" \
  --mp3 "shiiq_mp3/003-الفاتحة 1-آخرها.mp3" \
  --json-out "$OUT/audible_check.json"
audio_status=$?

[[ $test_status -eq 0 && $audio_status -eq 0 ]]
