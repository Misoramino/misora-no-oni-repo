"""Rough hiss proxy scan for bundled BGM/ambient MP3s.

Run: py tools/scan_audio_hiss.py

Measures boosted 8kHz+ RMS as a coarse static/hiss indicator (not perfect).
"""
from __future__ import annotations

import glob
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FFMPEG = "ffmpeg"


def find_ffmpeg() -> str:
    candidates = [
        r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages"
        r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
        r"\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",
        "ffmpeg",
    ]
    for c in candidates:
        try:
            if subprocess.run([c, "-version"], capture_output=True).returncode == 0:
                return c
        except OSError:
            continue
    raise RuntimeError("ffmpeg not found")


def astats_rms(ffmpeg: str, path: str, af: str) -> float | None:
    cmd = [ffmpeg, "-hide_banner", "-i", path, "-af", af, "-f", "null", "-"]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    for line in res.stderr.splitlines():
        if "RMS level dB:" in line:
            try:
                return float(line.split(":", 1)[1].strip())
            except ValueError:
                pass
    return None


def analyze(ffmpeg: str, path: str) -> dict:
    rel = os.path.relpath(path, ROOT)
    full_rms = astats_rms(ffmpeg, path, "astats=metadata=1:reset=1")
    hf_rms = astats_rms(
        ffmpeg,
        path,
        "highpass=f=8000,volume=20dB,astats=metadata=1:reset=1",
    )
    return {"path": rel, "rms_db": full_rms, "hf_hiss_proxy_db": hf_rms}


def main() -> None:
    ffmpeg = find_ffmpeg()
    patterns = [
        os.path.join(ROOT, "assets", "audio", "bgm", "*.mp3"),
        os.path.join(ROOT, "assets", "audio", "ambient", "*.mp3"),
    ]
    files = sorted({p for pat in patterns for p in glob.glob(pat)})
    rows = [analyze(ffmpeg, p) for p in files]
    rows.sort(key=lambda r: r["hf_hiss_proxy_db"] or -999.0, reverse=True)

    print("HF hiss proxy (8kHz+ RMS, +20dB) - higher = more sand/static tendency\n")
    print(f"{'file':<42} {'full RMS':>10} {'HF proxy':>10}")
    print("-" * 66)
    for row in rows:
        name = row["path"].replace("\\", "/")
        fr = row["rms_db"]
        hf = row["hf_hiss_proxy_db"]
        fr_s = f"{fr:8.1f}" if fr is not None else "     n/a"
        hf_s = f"{hf:8.1f}" if hf is not None else "     n/a"
        flag = " <<" if hf is not None and hf > -18 else ""
        print(f"{name:<42} {fr_s:>10} {hf_s:>10}{flag}")

    print("\nRoyal Classic lobby stack: royal_larghetto.mp3 + royal_fireplace.mp3 (ambient layer)")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001
        print(f"FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
