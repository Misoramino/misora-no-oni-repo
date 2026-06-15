"""Download, trim, and normalize world SFX from Mixkit.

Run from repo root:  py tools/prepare_world_sfx.py
Requires ffmpeg (same path as normalize_audio.py or on PATH).
"""
from __future__ import annotations

import os
import subprocess
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(ROOT, "tools", "_world_sfx_raw")
OUT_ROOT = os.path.join(ROOT, "assets", "audio", "sfx", "worlds")

FFMPEG_CANDIDATES = [
    r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",
    "ffmpeg",
]

# (world, slot, mixkit_id, trim_start, trim_duration, target_lufs)
P0_JOBS = [
    ("sciFi", "ui_tap", 2521, 0.0, 0.35, -22),
    ("sciFi", "reveal", 1022, 0.0, 0.55, -20),
    ("sciFi", "transition", 1093, 0.0, 0.75, -19),
    ("magical", "ui_tap", 3108, 0.0, 0.45, -23),
    ("magical", "reveal", 871, 0.0, 0.50, -21),
    ("magical", "transition", 2350, 0.0, 0.80, -19),
    ("horror", "ui_tap", 2585, 0.0, 0.30, -22),
    ("horror", "reveal", 1457, 0.0, 0.45, -20),
    ("horror", "transition", 1495, 0.0, 0.70, -19),
]

P1_JOBS = [
    # sport / Pop City
    ("sport", "ui_tap", 2568, 0.0, 0.35, -22),       # Cool interface click tone
    ("sport", "reveal", 2867, 0.0, 0.45, -21),       # Confirmation tone
    ("sport", "transition", 1489, 0.0, 0.72, -19),   # Air woosh
    # arg / Stealth Tactical
    ("arg", "ui_tap", 2544, 0.0, 0.35, -22),         # Metal button radio ping
    ("arg", "reveal", 895, 0.0, 0.52, -21),          # Sci-Fi radio waves
    ("arg", "transition", 2557, 0.0, 0.72, -19),     # Cassette player working
    # astronomy
    ("astronomy", "ui_tap", 902, 0.0, 0.38, -23),    # Water sci fi bleep
    ("astronomy", "reveal", 1583, 0.0, 0.58, -21),   # Futuristic radar ping
    ("astronomy", "transition", 3003, 0.0, 0.85, -19),  # Space deploy whizz
]

P2_JOBS = [
    # japaneseLuxury / 和風（高級）
    ("japaneseLuxury", "ui_tap", 3109, 0.0, 0.38, -23),   # Relaxing bell chime
    ("japaneseLuxury", "reveal", 930, 0.0, 0.50, -21),    # Bell of promise
    ("japaneseLuxury", "transition", 1474, 0.0, 0.75, -19),  # Transition windy swoosh
    # westernLuxury / 洋風（高級）
    ("westernLuxury", "ui_tap", 1061, 0.0, 0.35, -22),     # Clock ticker single
    ("westernLuxury", "reveal", 677, 0.0, 0.50, -21),     # Cinematic glass hit suspense
    ("westernLuxury", "transition", 1486, 0.0, 0.78, -19),  # Cinematic tunnel reverb woosh
]

JOBS = P0_JOBS + P1_JOBS + P2_JOBS

SFX_FILTER = "loudnorm=I={lufs}:TP=-2.0:LRA=7,alimiter=limit=0.92"


def find_ffmpeg() -> str:
    for candidate in FFMPEG_CANDIDATES:
        try:
            res = subprocess.run(
                [candidate, "-version"],
                capture_output=True,
                text=True,
            )
            if res.returncode == 0:
                return candidate
        except OSError:
            continue
    raise RuntimeError("ffmpeg not found")


def mixkit_url(mixkit_id: int) -> str:
    return f"https://assets.mixkit.co/active_storage/sfx/{mixkit_id}/{mixkit_id}.wav"


def download(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if os.path.exists(dest) and os.path.getsize(dest) > 1000:
        return
    print(f"  download {url}")
    urllib.request.urlretrieve(url, dest)


def process(ffmpeg: str, src: str, dst: str, start: float, duration: float, lufs: int) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    af = SFX_FILTER.format(lufs=lufs)
    cmd = [
        ffmpeg,
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-ss",
        str(start),
        "-t",
        str(duration),
        "-i",
        src,
        "-af",
        af,
        "-ac",
        "1",
        "-ar",
        "44100",
        "-c:a",
        "pcm_s16le",
        dst,
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        raise RuntimeError(f"ffmpeg failed for {dst}:\n{res.stderr}")


def main() -> None:
    ffmpeg = find_ffmpeg()
    print(f"ffmpeg: {ffmpeg}")
    ok = 0
    for world, slot, mixkit_id, start, duration, lufs in JOBS:
        raw = os.path.join(RAW_DIR, f"{mixkit_id}.wav")
        out = os.path.join(OUT_ROOT, world, f"{slot}.wav")
        print(f"== {world}/{slot}.wav (Mixkit #{mixkit_id}) ==")
        try:
            download(mixkit_url(mixkit_id), raw)
            process(ffmpeg, raw, out, start, duration, lufs)
            size = os.path.getsize(out)
            print(f"  ok -> {out} ({size // 1024} KB)")
            ok += 1
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED: {exc}", file=sys.stderr)
    print(f"\nDone: {ok}/{len(JOBS)}")
    if ok != len(JOBS):
        sys.exit(1)


if __name__ == "__main__":
    main()
