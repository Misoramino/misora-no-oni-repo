"""Export Royal Classic BGM from 音/ sources.

Run from repo root:  py tools/prepare_royal_bgm.py

Mapping (docs/world_audio_visual_decisions.md):
  royal_sarabande.mp3      <- Handel Water Music Sarabande
  royal_queen_of_sheba.mp3 <- Handel Arrival of the Queen of Sheba
  royal_larghetto.mp3      <- Dvorak Serenade Op.22 IV Larghetto
"""
from __future__ import annotations

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_ROOT = os.path.join(ROOT, "音")
DST = os.path.join(ROOT, "assets", "audio", "bgm")

FFMPEG_CANDIDATES = [
    r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",
    "ffmpeg",
]

BGM_LUFS = -15
BGM_FILTER = "loudnorm=I={lufs}:TP=-1.5:LRA=11,alimiter=limit=0.95"

LARGHETTO_SEARCH_DIRS = (
    os.path.join(SRC_ROOT, "BGM"),
    os.path.join(SRC_ROOT, "今回追加した分"),
    SRC_ROOT,
    DST,
)

LARGHETTO_MARKERS = ("larghetto", "dvorak", "dvořák", "serenade")


def find_ffmpeg() -> str:
    for c in FFMPEG_CANDIDATES:
        try:
            if subprocess.run([c, "-version"], capture_output=True).returncode == 0:
                return c
        except OSError:
            continue
    raise RuntimeError("ffmpeg not found")


def find_ffprobe(ffmpeg: str) -> str:
    probe = os.path.join(os.path.dirname(ffmpeg), "ffprobe.exe")
    if os.path.isfile(probe):
        return probe
    return "ffprobe"


def probe_duration(ffprobe: str, path: str) -> float:
    res = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            path,
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if res.returncode != 0:
        raise RuntimeError(res.stderr or "ffprobe failed")
    return float(res.stdout.strip())


def find_handel(contains: str) -> str:
    """Find Handel source under 音/ root or 今回追加した分/."""
    needles = (contains.lower(),)
    if contains.lower() == "sarabande":
        needles = ("sarabande",)
    elif "queen" in contains.lower() or "arrival" in contains.lower():
        needles = ("queen_of_sheba", "arrival")

    for folder in (SRC_ROOT, os.path.join(SRC_ROOT, "今回追加した分")):
        if not os.path.isdir(folder):
            continue
        for name in os.listdir(folder):
            lower = name.lower()
            if any(n in lower for n in needles):
                return os.path.join(folder, name)
    raise FileNotFoundError(f"no Handel file matching {contains!r} under {SRC_ROOT}")


def find_larghetto() -> str:
    for folder in LARGHETTO_SEARCH_DIRS:
        if not os.path.isdir(folder):
            continue
        for name in os.listdir(folder):
            lower = name.lower()
            if not any(m in lower for m in LARGHETTO_MARKERS):
                continue
            if not lower.endswith((".ogg", ".opus", ".mp3", ".wav", ".flac")):
                continue
            return os.path.join(folder, name)
    raise FileNotFoundError(
        "Dvorak Larghetto not found under 音/BGM, 音/今回追加した分, or assets/audio/bgm"
    )


def run(ffmpeg: str, args: list[str]) -> None:
    res = subprocess.run(
        [ffmpeg, "-y", "-hide_banner", "-loglevel", "error", *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if res.returncode != 0:
        raise RuntimeError(res.stderr or "ffmpeg failed")


def loop_bgm(
    ffmpeg: str,
    src: str,
    dst: str,
    start: float,
    seg_dur: float,
    extra_af: str,
    *,
    fade_in: float = 2.8,
    fade_out: float = 3.4,
) -> None:
    import tempfile

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    af = (
        f"afade=t=in:st=0:d={fade_in},"
        f"afade=t=out:st={max(0.1, seg_dur - fade_out)}:d={fade_out}"
    )
    if extra_af:
        af = f"{extra_af},{af}"
    af = f"{af},{BGM_FILTER.format(lufs=BGM_LUFS)}"

    with tempfile.TemporaryDirectory() as tmp:
        chunk = os.path.join(tmp, "chunk.mp3")
        run(
            ffmpeg,
            [
                "-ss",
                str(start),
                "-t",
                str(seg_dur),
                "-i",
                src,
                "-af",
                af,
                "-ar",
                "44100",
                "-c:a",
                "libmp3lame",
                "-b:a",
                "128k",
                chunk,
            ],
        )
        list_path = os.path.join(tmp, "list.txt")
        with open(list_path, "w", encoding="utf-8") as f:
            for _ in range(2):
                f.write(f"file '{chunk.replace(chr(92), '/')}'\n")
        run(
            ffmpeg,
            [
                "-f",
                "concat",
                "-safe",
                "0",
                "-i",
                list_path,
                "-c:a",
                "libmp3lame",
                "-b:a",
                "128k",
                dst,
            ],
        )


def export_larghetto(ffmpeg: str, ffprobe: str, src: str, dst: str) -> None:
    """Polish Dvorak Larghetto for lobby/match loop bed."""
    duration = probe_duration(ffprobe, src)
    # Leading/trailing silence trim + gentle string EQ; preserve natural tone.
    trim_af = (
        "silenceremove="
        "start_periods=1:start_duration=0.25:start_threshold=-42dB:"
        "stop_periods=1:stop_duration=0.35:stop_threshold=-42dB,"
        "highpass=f=55,lowpass=f=15500"
    )
    fade_in, fade_out = 1.0, 2.0
    # Loop segment: opening statement through first arc (~105s), capped by source.
    seg_dur = min(105.0, max(60.0, duration - fade_in - fade_out - 2.5))
    start = 0.0

    loop_bgm(
        ffmpeg,
        src,
        dst,
        start=start,
        seg_dur=seg_dur,
        extra_af=trim_af,
        fade_in=fade_in,
        fade_out=fade_out,
    )


def main() -> None:
    ffmpeg = find_ffmpeg()
    ffprobe = find_ffprobe(ffmpeg)
    sarabande = find_handel("Sarabande")
    queen = find_handel("Queen_of_Sheba")
    if not os.path.isfile(queen):
        queen = find_handel("Arrival")
    larghetto = find_larghetto()

    print(f"Sarabande: {os.path.basename(sarabande)}")
    print(f"Queen: {os.path.basename(queen)}")
    print(f"Larghetto: {larghetto}")

    loop_bgm(
        ffmpeg,
        sarabande,
        os.path.join(DST, "royal_sarabande.mp3"),
        start=0,
        seg_dur=82,
        extra_af="highpass=f=70,lowpass=f=14000",
    )
    print("  ok royal_sarabande.mp3")

    loop_bgm(
        ffmpeg,
        queen,
        os.path.join(DST, "royal_queen_of_sheba.mp3"),
        start=0,
        seg_dur=75,
        extra_af="highpass=f=80,lowpass=f=15000",
    )
    print("  ok royal_queen_of_sheba.mp3")

    export_larghetto(
        ffmpeg,
        ffprobe,
        larghetto,
        os.path.join(DST, "royal_larghetto.mp3"),
    )
    print("  ok royal_larghetto.mp3 (Dvorak Serenade Op.22 IV Larghetto)")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001
        print(f"FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
