"""Tiny UI driver for an installed app on an Android emulator, through the
accessibility tree (uiautomator dump): Flutter exposes its semantics labels
as content descriptions. Used by fresh_install_check.sh.

  python3 -I tool/device/android_ui.py SERIAL tap  REGEX [timeout_s]
  python3 -I tool/device/android_ui.py SERIAL wait REGEX [timeout_s]
  python3 -I tool/device/android_ui.py SERIAL find REGEX [timeout_s]
  python3 -I tool/device/android_ui.py SERIAL shot PATH

`tap` taps the centre of the first element whose content description or
text fully matches REGEX, once it appears; prints the host time of the tap
(epoch ms); `find` prints its centre "x y" without tapping. Exit code 1
if it never appears.
"""
import html
import re
import subprocess
import sys
import time

NODE = re.compile(r"<node [^>]*>")


def adb(serial, *args):
    return subprocess.run(["adb", "-s", serial, *args], check=True,
                          capture_output=True).stdout


def find(serial, pattern):
    adb(serial, "shell", "uiautomator", "dump", "/sdcard/sheekh_ui.xml")
    xml = adb(serial, "shell", "cat", "/sdcard/sheekh_ui.xml").decode("utf-8")
    rx = re.compile(pattern, re.S)
    for m in NODE.finditer(xml):
        node = m.group(0)
        desc = html.unescape(re.search(r'content-desc="([^"]*)"', node).group(1))
        text = html.unescape(re.search(r' text="([^"]*)"', node).group(1))
        if rx.fullmatch(desc) or rx.fullmatch(text):
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", re.search(
                r'bounds="([^"]*)"', node).group(1)))
            return (x1 + x2) // 2, (y1 + y2) // 2
    return None


def main():
    serial, cmd, arg = sys.argv[1], sys.argv[2], sys.argv[3]
    timeout = float(sys.argv[4]) if len(sys.argv) > 4 else 20
    if cmd == "shot":
        with open(arg, "wb") as f:
            f.write(adb(serial, "exec-out", "screencap", "-p"))
        return 0
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            at = find(serial, arg)
        except subprocess.CalledProcessError:
            at = None  # no dump while the app starts or redraws: retry
        if at:
            if cmd == "tap":
                adb(serial, "shell", "input", "tap", str(at[0]), str(at[1]))
                print(int(time.time() * 1000))
            elif cmd == "find":
                print(at[0], at[1])
            return 0
        time.sleep(0.5)
    print(f"not found: {arg}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
