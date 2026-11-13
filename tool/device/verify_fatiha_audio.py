"""Checks that each ayah tap on the emulator was AUDIBLE and came from the
right place in the Sheikh's original recording.

Inputs: the integration test log (EVIDENCE lines), a capture of what the
emulator actually played (recorded on the host from the emulator's audio
output stream), and the original MP3 (read only, never modified).

For every tap it takes a 3-second slice of the capture shortly after playback
started and:
  * measures its loudness against a silent stretch captured after playback
    stopped (audible: at least 30 dB above that silence);
  * splits it into six 0.5-second windows and finds, independently for each,
    where in the original recording it comes from (normalised
    cross-correlation within +/-20 s). The tap passes only if at least 4 of
    the 6 windows land within 0.3 s of the expected point of the timeline,
    after one latency shared by all taps (capped at 0.5 s) is allowed for:
    what was heard, not what the player reports. By chance a window lands
    there with a probability of about 1.5 %.

Exit code 0 only if every tap was audible and matched the expected point
in its segment.

Needs numpy and miniaudio (MP3 decoding):
  python -I tool/device/verify_fatiha_audio.py --log L --wav W --wav-start-ms T
         --device-offset-ms O --mp3 M
"""

import argparse
import json
import sys
import wave

import miniaudio
import numpy as np

RATE = 16000
SLICE_S = 3.0
SKIP_S = 1.0  # skip the first second after "playing" (output latency)
SEARCH_S = 20.0
WINDOW_S = 0.5
TOLERANCE_S = 0.3
MAX_LATENCY_S = 0.5


def load_capture(path):
    with wave.open(path, "rb") as w:
        assert w.getsampwidth() == 2, "expected 16-bit capture"
        rate, ch = w.getframerate(), w.getnchannels()
        data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    data = data.reshape(-1, ch).mean(axis=1) if ch > 1 else data
    if rate != RATE:
        raise SystemExit(f"capture must be {RATE} Hz, got {rate}")
    return data.astype(np.float64) / 32768.0


def load_original(path):
    d = miniaudio.decode_file(
        path,
        output_format=miniaudio.SampleFormat.SIGNED16,
        nchannels=1,
        sample_rate=RATE,
    )
    return np.frombuffer(d.samples, dtype=np.int16).astype(np.float64) / 32768.0


def dbfs(x):
    rms = np.sqrt(np.mean(x * x)) if len(x) else 0.0
    return 20 * np.log10(max(rms, 1e-9))


def locate(snippet, original, centre_s):
    """Best match of snippet in original near centre_s: (time_s, ncc)."""
    lo = max(0, int((centre_s - SEARCH_S) * RATE))
    hi = min(len(original), int((centre_s + SEARCH_S) * RATE) + len(snippet))
    region = original[lo:hi]
    x = snippet - snippet.mean()
    n = len(x)
    if len(region) < n or np.linalg.norm(x) == 0:
        return None, 0.0
    size = 1 << int(np.ceil(np.log2(len(region) + n)))
    corr = np.fft.irfft(np.fft.rfft(region, size) * np.conj(np.fft.rfft(x, size)), size)
    corr = corr[: len(region) - n + 1]
    c2 = np.concatenate([[0.0], np.cumsum(region * region)])
    c1 = np.concatenate([[0.0], np.cumsum(region)])
    win_energy = (c2[n:] - c2[:-n]) - (c1[n:] - c1[:-n]) ** 2 / n
    ncc = corr / (np.sqrt(np.maximum(win_energy, 1e-12)) * np.linalg.norm(x))
    best = int(np.argmax(ncc))
    return (lo + best) / RATE, float(ncc[best])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True)
    ap.add_argument("--wav", required=True)
    ap.add_argument("--wav-start-ms", type=int, required=True)
    ap.add_argument("--device-offset-ms", type=int, default=0,
                    help="device clock minus host clock")
    ap.add_argument("--mp3", required=True)
    ap.add_argument("--json-out")
    a = ap.parse_args()

    events = []
    with open(a.log, encoding="utf-8", errors="replace") as f:
        for line in f:
            i = line.find("EVIDENCE {")
            if i >= 0:
                events.append(json.loads(line[i + len("EVIDENCE "):].strip()))
    taps = [e for e in events if e["test"] == "review"]
    quiet = next((e for e in events if e["test"] == "silence"), None)
    if not taps or quiet is None:
        print("No review-mode evidence in the log: the test did not run.")
        return 2

    cap = load_capture(a.wav)
    orig = load_original(a.mp3)

    def cap_index(device_epoch_ms):
        host_ms = device_epoch_ms - a.device_offset_ms
        return int((host_ms - a.wav_start_ms) / 1000 * RATE)

    q0, q1 = cap_index(quiet["fromEpochMs"]), cap_index(quiet["toEpochMs"])
    silence_db = dbfs(cap[max(q0, 0):max(q1, 0)])

    # Pass 1: locate every 0.5 s window of every tap.
    win = int(WINDOW_S * RATE)
    per_tap = []
    for e in taps:
        start = cap_index(e["playingAtEpochMs"]) + int(SKIP_S * RATE)
        snippet = cap[start:start + int(SLICE_S * RATE)]
        expected_s = (e["positionAtPlayingMs"] / 1000.0) + SKIP_S
        windows = []
        for k in range(int(SLICE_S / WINDOW_S)):
            want = expected_s + k * WINDOW_S
            at, ncc = locate(snippet[k * win:(k + 1) * win], orig, want)
            windows.append((want, at, ncc))
        per_tap.append((e, snippet, expected_s, windows))

    # One latency shared by all taps (audio output delay plus clock-offset
    # error): the median of (found - expected). It is capped: a shift larger
    # than MAX_LATENCY_S is never absorbed, so audio from the wrong place
    # can't be explained away.
    deltas = [at - want for _, _, _, ws in per_tap for want, at, _ in ws
              if at is not None]
    latency = float(np.median(deltas)) if deltas else 0.0
    if abs(latency) > MAX_LATENCY_S:
        print(f"Shared offset {latency:+.2f} s is implausible; not applied.")
        latency = 0.0
    print(f"Shared output latency / clock offset: {latency:+.2f} s")

    rows, ok_all = [], True
    for e, snippet, expected_s, windows in per_tap:
        level = dbfs(snippet)
        hits = sum(1 for want, at, _ in windows
                   if at is not None and abs(at - want - latency) <= TOLERANCE_S)
        found = [None if at is None else round(at, 2) for _, at, _ in windows]
        first = found[0]
        seg_lo, seg_hi = e["segmentStartMs"] / 1000.0, e["segmentEndMs"] / 1000.0
        audible = level > silence_db + 30 and level > -70
        in_segment = seg_lo - 0.5 <= expected_s <= seg_hi
        matched = hits >= 4
        ok = audible and matched and in_segment
        ok_all &= ok
        rows.append({
            "ayah": e["ayah"],
            "segment": e["segment"],
            "reviewed": e["reviewed"],
            "segmentStartMs": e["segmentStartMs"],
            "playerPositionAtPlayingMs": e["positionAtPlayingMs"],
            "levelDbfs": round(level, 1),
            "heardFromRecordingAtS": first,
            "windowsFoundAtS": found,
            "windowNcc": [round(n, 2) for _, _, n in windows],
            "windowsOnTimeline": hits,
            "expectedS": round(expected_s, 2),
            "audible": bool(audible),
            "ok": bool(ok),
        })

    def t(s):
        return f"{int(s // 60)}:{s % 60:05.2f}"

    print(f"Silence after stop: {silence_db:.1f} dBFS")
    print("ayah | segment  | reviewed | level dBFS | heard from (recording) | expected | windows on timeline | result")
    for r in rows:
        heard = "-" if r["heardFromRecordingAtS"] is None else t(r["heardFromRecordingAtS"])
        print(f"{r['ayah']:>4} | {r['segment']:<8} | {str(r['reviewed']):<8} | "
              f"{r['levelDbfs']:>10} | {heard:>22} | {t(r['expectedS']):>8} | "
              f"{r['windowsOnTimeline']:>13} of 6 | {'PASS' if r['ok'] else 'FAIL'}")
    if a.json_out:
        with open(a.json_out, "w", encoding="utf-8") as f:
            json.dump({"silenceDbfs": round(silence_db, 1),
                       "sharedLatencyS": round(latency, 3), "taps": rows}, f, indent=2)
    print("AUDIBLE CHECK:", "PASSED" if ok_all else "FAILED")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
