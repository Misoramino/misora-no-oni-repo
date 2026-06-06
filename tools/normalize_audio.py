"""Normalize provided BGM/ambient audio into assets with loudness matching.

Run from repo root:  python tools/normalize_audio.py
Requires ffmpeg (installed via winget Gyan.FFmpeg).
"""
import os
import subprocess
import sys
import unicodedata

FFMPEG = r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_BGM = os.path.join(ROOT, "音", "BGM")
SRC_AMB = os.path.join(ROOT, "音", "環境音・効果音")
DST_BGM = os.path.join(ROOT, "assets", "audio", "bgm")
DST_AMB = os.path.join(ROOT, "assets", "audio", "ambient")

# loudnorm: integrated loudness / true-peak / loudness-range.
# BGM a touch louder than ambient so match ambience stays in the background.
BGM_FILTER = "loudnorm=I=-15:TP=-1.5:LRA=11,alimiter=limit=0.95"
AMB_FILTER = "loudnorm=I=-21:TP=-2.0:LRA=13,alimiter=limit=0.9"

BGM_MAP = {
    "ホラー.mp3": "horror.mp3",
    "ポップ１.mp3": "pop.mp3",
    "ポップ２.mp3": "pop2.mp3",
    "サイバー.mp3": "cyber.mp3",
    "タクティカル.mp3": "tactical.mp3",
    "魔法.mp3": "magical.mp3",
    "宇宙.mp3": "space.mp3",
    "ファンキー.mp3": "funky.mp3",
}
AMB_MAP = {
    "風の音.mp3": "wind.mp3",
    "森の妖精.mp3": "forest.mp3",
    "通信.mp3": "comms.mp3",
    "ソナー.mp3": "sonar.mp3",
    "ポップな街に宇宙船みたいなのが通った音.mp3": "pop_city.mp3",
    "ビープ音.mp3": "beep.mp3",
}


def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


def index_dir(path: str):
    table = {}
    for name in os.listdir(path):
        table[nfc(name)] = os.path.join(path, name)
    return table


def convert(src: str, dst: str, audio_filter: str, bitrate: str = "128k") -> bool:
    cmd = [
        FFMPEG, "-y", "-hide_banner", "-loglevel", "error",
        "-i", src,
        "-af", audio_filter,
        "-c:a", "libmp3lame", "-b:a", bitrate, "-ar", "44100",
        dst,
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        print(f"  ! ffmpeg failed: {os.path.basename(dst)}\n{res.stderr}")
        return False
    return True


def run(src_dir, dst_dir, mapping, audio_filter, label):
    os.makedirs(dst_dir, exist_ok=True)
    table = index_dir(src_dir)
    ok = 0
    for jp, ascii_name in mapping.items():
        src = table.get(nfc(jp))
        if not src:
            print(f"  ? missing source: {jp}")
            continue
        dst = os.path.join(dst_dir, ascii_name)
        if convert(src, dst, audio_filter):
            size = os.path.getsize(dst)
            print(f"  ok {ascii_name:14s} {size//1024:>6d} KB")
            ok += 1
    print(f"[{label}] {ok}/{len(mapping)} done")


def main():
    if not os.path.exists(FFMPEG):
        print("ffmpeg not found at expected path", file=sys.stderr)
        sys.exit(1)
    print("== BGM ==")
    run(SRC_BGM, DST_BGM, BGM_MAP, BGM_FILTER, "bgm")
    print("== Ambient ==")
    run(SRC_AMB, DST_AMB, AMB_MAP, AMB_FILTER, "ambient")


if __name__ == "__main__":
    main()
