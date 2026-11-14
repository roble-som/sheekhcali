"""Black-box check of what an installed app actually PLAYED after each ayah
tap: no timing or state from inside the app, only the host's tap times, a
capture of the emulator's own audio output, and the original recording
(read only).

For every tap:
  * analysis starts 2 s after the tap ("skipS"), or at the first audible
    moment after the tap if that is later (a cold start: the player loads);
  * a 3-second snippet from there is located near the start of the ayah's
    segment (no earlier than 1 s before it, no later than the time elapsed
    since the tap + 1 s) and, for comparison, anywhere in the WHOLE
    original recording (normalised cross-correlation). The Sheikh recites
    some ayahs several times, so similar speech exists elsewhere; the tap
    passes only if the match at the segment start is at least 85 % as
    strong as the best match anywhere, six 0.5-second windows follow the
    recording's timeline from there (at least 4 of 6 within 0.3 s), and the
    snippet is audible (above -60 dBFS and 30 dB over the idle level).
    The located point must also be no earlier than 0.7 s before the
    segment start and no later than the time elapsed since the tap plus
    0.75 s (capture start and output latency): playback began at that
    ayah's segment start, after the tap;
  * if the tap is marked `expectStop`, the capture must be audible just
    before the segment's end and at least 40 dB quieter (and below
    -70 dBFS) from 1 s after it: playback stopped at the segment end.

Segments are chosen exactly as the app chooses them (candidates file: the
first explanation span of that ayah alone, else the first shared one).

Usage:
  python -I tool/device/verify_heard_segments.py --wav W --wav-start-ms T
      --taps taps.json --mp3 M --candidates C [--json-out J]
taps.json: {"silence": [fromMs, toMs], "taps": [{"ayah": 3,
            "tapMs": 1790000000000, "label": "...", "expectStop": true,
            "skipS": 2}]}
(all times are host epoch milliseconds). Needs numpy and miniaudio.
"""

import argparse
import json
import sys
import wave

import miniaudio
import numpy as np

CAPTURE_RATE = 16000
RATE = 8000  # analysis rate (both signals decimated the same way)
WINDOW_S = 0.5
WINDOWS = 6
COARSE_S = 3.0
LOCAL_S = 3.0
AGREE_S = 0.3
SKIP_S = 2.0
AUDIBLE_FLOOR = -60.0
# Allowance for the capture's start time (taken just before pw-record
# starts) and the output path's latency; the earlier verifier allowed the
# same 0.5-0.75 s.
LATENCY_S = 0.75


def decimate(x, factor):
    n = len(x) // factor * factor
    return x[:n].reshape(-1, factor).mean(axis=1)


def dbfs(x):
    if len(x) == 0:
        return -200.0
    return 20 * np.log10(np.sqrt(np.mean(np.square(x))) + 1e-12)


def load_capture(path):
    with wave.open(path, "rb") as w:
        assert w.getsampwidth() == 2 and w.getframerate() == CAPTURE_RATE
        ch = w.getnchannels()
        data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    data = data.reshape(-1, ch).mean(axis=1) if ch > 1 else data
    return data.astype(np.float64) / 32768.0


def load_original(path):
    d = miniaudio.decode_file(path, output_format=miniaudio.SampleFormat.SIGNED16,
                              nchannels=1, sample_rate=CAPTURE_RATE)
    return np.asarray(d.samples, dtype=np.float64) / 32768.0


class Locator:
    """Finds a short window anywhere in the original (FFT correlation)."""

    def __init__(self, original):
        self.x = original
        self.size = 1 << int(np.ceil(np.log2(len(original) + RATE)))
        self.fx = np.fft.rfft(original, self.size)
        c = np.concatenate([[0.0], np.cumsum(np.square(original))])
        self.energy = c

    def locate_near(self, w, centre_s, radius_s):
        n = len(w)
        lo = max(int((centre_s - radius_s) * RATE), 0)
        hi = min(int((centre_s + radius_s) * RATE) + n, len(self.x))
        seg = self.x[lo:hi]
        if len(seg) <= n:
            return None, 0.0
        w = w - w.mean()
        nw = np.sqrt(np.sum(w * w))
        if nw < 1e-9:
            return None, 0.0
        corr = np.correlate(seg, w, mode="valid")
        c = np.concatenate([[0.0], np.cumsum(np.square(seg))])
        e = c[n:n + len(corr)] - c[:len(corr)]
        ncc = corr / (np.sqrt(np.maximum(e, 1e-12)) * nw)
        i = int(np.argmax(ncc))
        return (lo + i) / RATE, float(ncc[i])

    def locate(self, w):
        w = w - w.mean()
        n = len(w)
        norm_w = np.sqrt(np.sum(w * w))
        if norm_w < 1e-9:
            return None, 0.0
        corr = np.fft.irfft(self.fx * np.conj(np.fft.rfft(w, self.size)), self.size)
        corr = corr[: len(self.x) - n]
        e = self.energy[n:n + len(corr)] - self.energy[: len(corr)]
        ncc = corr / (np.sqrt(np.maximum(e, 1e-12)) * norm_w)
        i = int(np.argmax(ncc))
        return i / RATE, float(ncc[i])


def segment_for(spans, ayah):
    """As the app's pickExplanation: the first explanation of the ayah
    alone, else the first one shared with other ayahs."""
    shared = None
    for s in spans:
        if s["kind"] != "explanation" or ayah not in s["ayahs"]:
            continue
        if len(s["ayahs"]) == 1:
            return s
        shared = shared or s
    return shared


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--wav", required=True)
    ap.add_argument("--wav-start-ms", type=int, required=True)
    ap.add_argument("--taps", required=True)
    ap.add_argument("--mp3", required=True)
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--json-out")
    a = ap.parse_args()

    plan = json.load(open(a.taps, encoding="utf-8"))
    spans = json.load(open(a.candidates, encoding="utf-8"))["spans"]
    cap = decimate(load_capture(a.wav), CAPTURE_RATE // RATE)
    loc = Locator(decimate(load_original(a.mp3), CAPTURE_RATE // RATE))

    def idx(host_ms):
        return int((host_ms - a.wav_start_ms) / 1000 * RATE)

    s0, s1 = (idx(t) for t in plan["silence"])
    silence = dbfs(cap[max(s0, 0):max(s1, 0)])
    frame = RATE // 20  # 50 ms
    taps = plan["taps"]
    rows, ok_all = [], True
    for k, t in enumerate(taps):
        seg = segment_for(spans, t["ayah"])
        tap = idx(t["tapMs"])
        end = idx(taps[k + 1]["tapMs"]) if k + 1 < len(taps) else len(cap)
        threshold = max(silence + 25, AUDIBLE_FLOOR)
        onset = None
        for f in range(tap, end - frame, frame):
            if dbfs(cap[f:f + frame]) > threshold:
                onset = f
                break
        row = {"ayah": t["ayah"], "label": t.get("label", ""),
               "segment": seg and seg["id"], "segmentStartS": seg and seg["startMs"] / 1000,
               "segmentEndS": seg and seg["endMs"] / 1000}
        if onset is None or seg is None:
            row.update(audible=False, ok=False)
            rows.append(row)
            ok_all = False
            continue
        start = max(tap + int(t.get("skipS", SKIP_S) * RATE), onset)
        elapsed = (start - tap) / RATE
        coarse = cap[start:start + int(COARSE_S * RATE)]
        seg_start = seg["startMs"] / 1000
        best_any, best_any_ncc = loc.locate(coarse)
        lo_s, hi_s = seg_start - 1.0, seg_start + elapsed + 1.0
        heard, heard_ncc = loc.locate_near(coarse, (lo_s + hi_s) / 2, (hi_s - lo_s) / 2)
        win = int(WINDOW_S * RATE)
        agree, nccs = 0, []
        for j in range(WINDOWS):
            w = cap[start + j * win:start + (j + 1) * win]
            at, ncc = loc.locate_near(w, heard + j * WINDOW_S, LOCAL_S) if heard is not None else (None, 0.0)
            nccs.append(round(ncc, 2))
            if at is not None and abs(at - (heard + j * WINDOW_S)) <= AGREE_S:
                agree += 1
        level = dbfs(coarse)
        audible = level > AUDIBLE_FLOOR and level > silence + 30
        in_place = (heard is not None
                    and seg_start - 0.7 <= heard <= seg_start + elapsed + LATENCY_S)
        strongest = heard is not None and heard_ncc >= 0.85 * best_any_ncc
        ok = audible and agree >= 4 and in_place and strongest
        row.update(
            analysedAfterTapS=round(elapsed, 2),
            levelDbfs=round(level, 1),
            heardFromS=None if heard is None else round(heard, 2),
            matchNcc=round(heard_ncc, 3),
            bestAnywhereS=round(best_any, 2),
            bestAnywhereNcc=round(best_any_ncc, 3),
            windowsAgree=agree,
            windowNcc=nccs,
            audible=bool(audible),
            inSegmentStart=bool(in_place),
        )
        if t.get("expectStop") and heard is None:
            ok = False
        elif t.get("expectStop"):
            # Where the segment end falls in the capture, from the heard point.
            end_at = start + int((seg["endMs"] / 1000 - heard) * RATE)
            before = dbfs(cap[max(end_at - 3 * RATE, start):end_at - RATE // 2])
            after = dbfs(cap[end_at + RATE:end_at + 5 * RATE])
            stopped = before > AUDIBLE_FLOOR and after < before - 40 and after < -70
            row.update(segmentLengthS=(seg["endMs"] - seg["startMs"]) / 1000,
                       levelBeforeEndDbfs=round(before, 1),
                       levelAfterEndDbfs=round(after, 1), stoppedAtEnd=bool(stopped))
            ok = ok and stopped
        row["ok"] = bool(ok)
        ok_all &= ok
        rows.append(row)

    def mmss(s):
        return "-" if s is None else f"{int(s // 60)}:{s % 60:05.2f}"

    print(f"Idle output level: {silence:.1f} dBFS")
    print("ayah | label                | after tap | level dBFS | heard from | segment starts | match / best anywhere | agree | stop check | result")
    for r in rows:
        stop = "-" if "stoppedAtEnd" not in r else (
            f"{'stopped' if r['stoppedAtEnd'] else 'NOT stopped'} "
            f"({r['levelBeforeEndDbfs']}→{r['levelAfterEndDbfs']})")
        print(f"{r['ayah']:>4} | {r['label'][:20]:<20} | {r.get('analysedAfterTapS', '-'):>8}s | {r.get('levelDbfs', '-'):>10} | "
              f"{mmss(r.get('heardFromS')):>10} | {mmss(r['segmentStartS']):>14} | "
              f"{r.get('matchNcc', '-')} / {r.get('bestAnywhereNcc', '-')} @{mmss(r.get('bestAnywhereS'))} | "
              f"{r.get('windowsAgree', 0)} of 6 | {stop} | {'PASS' if r['ok'] else 'FAIL'}")
    if a.json_out:
        with open(a.json_out, "w", encoding="utf-8") as f:
            json.dump({"silenceDbfs": round(silence, 1), "taps": rows}, f, indent=2,
                      ensure_ascii=False)
    print("HEARD-SEGMENT CHECK:", "PASSED" if ok_all else "FAILED")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
