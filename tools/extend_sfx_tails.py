"""Add soft reverb tail to moment SFX (reveal/capture/unlock/result)."""
from __future__ import annotations

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORLDS = os.path.join(ROOT, "assets", "audio", "sfx", "worlds")
SLOTS = (
    "reveal.wav",
    "capture.wav",
    "anon_reveal.wav",
    "accusation_unlock.wav",
    "result_sting.wav",
    "lose_sting.wav",
)
FFMPEG = r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
TAIL_AF = "aecho=0.55:0.62:18:0.22,apad=pad_dur=0.22,afade=t=out:st=0:d=0.28"


def main() -> None:
    ok = 0
    for world in os.listdir(WORLDS):
        wd = os.path.join(WORLDS, world)
        if not os.path.isdir(wd):
            continue
        for slot in SLOTS:
            path = os.path.join(wd, slot)
            if not os.path.isfile(path):
                continue
            tmp = path + ".tmp.wav"
            cmd = [
                FFMPEG,
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                path,
                "-af",
                TAIL_AF,
                tmp,
            ]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print(f"FAIL {world}/{slot}: {res.stderr}", file=sys.stderr)
                continue
            os.replace(tmp, path)
            print(f"ok {world}/{slot}")
            ok += 1
    print(f"Done: {ok} files")


if __name__ == "__main__":
    main()
