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
    # sciFi / Cyber Night — Phase B: low data tick, intrusion hint, UI sweep
    ("sciFi", "ui_tap", 900, 0.0, 0.32, -23),          # Sci fi click
    ("sciFi", "reveal", 911, 0.0, 0.52, -21),          # Interface hint notification
    ("sciFi", "transition", 3114, 0.0, 0.72, -19),     # Fast sci fi transition sweep
    ("magical", "ui_tap", 3108, 0.0, 0.45, -23),
    ("magical", "reveal", 871, 0.0, 0.50, -21),
    ("magical", "transition", 2350, 0.0, 0.80, -19),
    # horror / Urban Horror — Phase B: cassette, VHS static, creepy radio
    ("horror", "ui_tap", 2556, 0.0, 0.28, -24),        # Cassette player
    ("horror", "reveal", 2561, 0.0, 0.38, -22),        # Radio static fx
    ("horror", "transition", 2558, 0.0, 0.68, -21),   # Creepy radio frequency
]

P1_JOBS = [
    # sport / Pop City — unchanged Phase B
    ("sport", "ui_tap", 2568, 0.0, 0.35, -22),
    ("sport", "reveal", 2867, 0.0, 0.45, -21),
    ("sport", "transition", 1489, 0.0, 0.72, -19),
    # arg / Stealth Tactical — Phase B: low terminal click, scan ping, radio swell
    ("arg", "ui_tap", 2577, 0.0, 0.30, -24),           # Interface device click
    ("arg", "reveal", 905, 0.0, 0.50, -22),            # Scanning sci fi alarm
    ("arg", "transition", 2554, 0.0, 0.72, -20),       # Radio frequency signal swell
    # astronomy — Phase B: space comm, deep signal, quiet whoosh
    ("astronomy", "ui_tap", 2549, 0.0, 0.32, -24),     # Astronaut radio communication
    ("astronomy", "reveal", 2555, 0.0, 0.48, -22),      # Alien radio frequency call
    ("astronomy", "transition", 3001, 0.0, 0.80, -20), # Space shot whoosh
]

P2_JOBS = [
    # japaneseLuxury — Phase B: wood drop, paper chime, shoji slide
    ("japaneseLuxury", "ui_tap", 3141, 0.0, 0.28, -23),   # Small wood plank pile drop
    ("japaneseLuxury", "reveal", 1107, 0.0, 0.40, -22),    # Page forward single chime
    ("japaneseLuxury", "transition", 191, 0.0, 0.68, -20), # Wooden long sliding door
    # westernLuxury — light volume tweak only (assets unchanged)
    ("westernLuxury", "ui_tap", 1061, 0.0, 0.35, -22),
    ("westernLuxury", "reveal", 677, 0.0, 0.50, -21),
    ("westernLuxury", "transition", 1486, 0.0, 0.78, -19),
]

JOBS = P0_JOBS + P1_JOBS + P2_JOBS

# Phase C — 場面別世界観 SE（anon_reveal / capture / accusation_unlock / countdown）
P3_MOMENT_JOBS = [
    # sciFi / Cyber Night
    ("sciFi", "anon_reveal", 2548, 0.0, 0.22, -26),       # Digital signal interference
    ("sciFi", "capture", 1022, 0.0, 0.55, -19),            # Cinematic sci fi glitch
    ("sciFi", "accusation_unlock", 266, 0.0, 0.48, -21),   # Sci-Fi positive notification
    ("sciFi", "countdown", 903, 0.0, 0.22, -24),           # Fast sci fi bleep
    # magical
    ("magical", "anon_reveal", 871, 0.0, 0.28, -25),       # Fairy magic sparkle
    ("magical", "capture", 3203, 0.0, 0.52, -20),          # Electro hit
    ("magical", "accusation_unlock", 2350, 0.0, 0.55, -20), # Magic sparkle whoosh
    ("magical", "countdown", 3108, 0.0, 0.22, -25),        # Crystal chime
    # horror / Urban Horror
    ("horror", "anon_reveal", 2559, 0.0, 0.22, -26),       # Static radio noise sound
    ("horror", "capture", 757, 0.0, 0.50, -20),             # Falling hit
    ("horror", "accusation_unlock", 2557, 0.0, 0.65, -22),  # Cassette player working
    ("horror", "countdown", 2561, 0.0, 0.18, -25),          # Radio static fx
    # sport / Pop City
    ("sport", "anon_reveal", 265, 0.0, 0.22, -24),          # Quick positive notification
    ("sport", "capture", 1512, 0.0, 0.40, -20),             # Game whip shot
    ("sport", "accusation_unlock", 2867, 0.0, 0.42, -21),    # Confirmation tone
    ("sport", "countdown", 2568, 0.0, 0.20, -24),           # Cool interface click tone
    # arg / Stealth Tactical
    ("arg", "anon_reveal", 2545, 0.0, 0.20, -26),           # Distorted radio signal
    ("arg", "capture", 3203, 0.0, 0.50, -20),               # Electro hit
    ("arg", "accusation_unlock", 914, 0.0, 0.48, -21),      # Sci Fi confirmation
    ("arg", "countdown", 2577, 0.0, 0.18, -25),              # Interface device click
    # astronomy
    ("astronomy", "anon_reveal", 2545, 0.0, 0.22, -26),      # Distorted radio signal
    ("astronomy", "capture", 774, 0.0, 0.55, -20),           # Space impact
    ("astronomy", "accusation_unlock", 914, 0.0, 0.50, -21), # Sci Fi confirmation
    ("astronomy", "countdown", 2549, 0.0, 0.20, -25),        # Astronaut radio communication
    # japaneseLuxury
    ("japaneseLuxury", "anon_reveal", 1530, 0.0, 0.20, -26),  # Paper slide
    ("japaneseLuxury", "capture", 2182, 0.0, 0.48, -20),     # Wood hard hit
    ("japaneseLuxury", "accusation_unlock", 187, 0.0, 0.55, -21),  # Old medieval door lock
    ("japaneseLuxury", "countdown", 176, 0.0, 0.22, -24),    # Short creaking floorboard
    # westernLuxury
    ("westernLuxury", "anon_reveal", 1061, 0.0, 0.18, -26),  # Clock ticker single
    ("westernLuxury", "capture", 2858, 0.0, 0.52, -20),      # Gear metallic lock sound
    ("westernLuxury", "accusation_unlock", 187, 0.0, 0.60, -21),  # Old medieval door lock
    ("westernLuxury", "countdown", 1061, 0.0, 0.20, -25),     # Clock ticker single
]

JOBS = P0_JOBS + P1_JOBS + P2_JOBS + P3_MOMENT_JOBS

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
