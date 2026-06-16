"""Polish pass — BGM / Ambient / SFX from 音/今回追加した分 and legacy sources.

Run from repo root:  py tools/prepare_polish_audio.py
Does not delete or move source files.
"""
from __future__ import annotations

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_ADDED = os.path.join(ROOT, "音", "今回追加した分")
SRC_AMB = os.path.join(ROOT, "音", "環境音・効果音")
DST_BGM = os.path.join(ROOT, "assets", "audio", "bgm")
DST_AMB = os.path.join(ROOT, "assets", "audio", "ambient")
DST_SFX = os.path.join(ROOT, "assets", "audio", "sfx", "worlds")

FFMPEG_CANDIDATES = [
    r"C:\Users\misor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",
    "ffmpeg",
]

BGM_LUFS = -15
AMB_LUFS = -36  # very quiet for long-form ambient
AMB_DEEP_LUFS = -38
SFX_LUFS = -24

BGM_FILTER = "loudnorm=I={lufs}:TP=-1.5:LRA=11,alimiter=limit=0.95"
AMB_FILTER = "loudnorm=I={lufs}:TP=-2.5:LRA=9,alimiter=limit=0.88"
SFX_FILTER = "loudnorm=I={lufs}:TP=-2.0:LRA=7,alimiter=limit=0.92"


def find_ffmpeg() -> str:
    for c in FFMPEG_CANDIDATES:
        try:
            if subprocess.run([c, "-version"], capture_output=True).returncode == 0:
                return c
        except OSError:
            continue
    raise RuntimeError("ffmpeg not found")


def find_src(folder: str, contains: str) -> str:
    for name in os.listdir(folder):
        if contains.lower() in name.lower():
            return os.path.join(folder, name)
    raise FileNotFoundError(f"no file matching {contains!r} in {folder}")


def run_ffmpeg(ffmpeg: str, args: list[str]) -> None:
    cmd = [ffmpeg, "-y", "-hide_banner", "-loglevel", "error", *args]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        raise RuntimeError(res.stderr or "ffmpeg failed")


def export_mp3(
    ffmpeg: str,
    src: str,
    dst: str,
    start: float,
    duration: float,
    extra_af: str,
    lufs: int,
    amb_filter: str = AMB_FILTER,
) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    af = amb_filter.format(lufs=lufs)
    if extra_af:
        af = f"{extra_af},{af}"
    run_ffmpeg(
        ffmpeg,
        [
            "-ss",
            str(start),
            "-t",
            str(duration),
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
            dst,
        ],
    )


def export_wav(
    ffmpeg: str,
    src: str,
    dst: str,
    start: float,
    duration: float,
    extra_af: str,
    lufs: int,
) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    af = SFX_FILTER.format(lufs=lufs)
    if extra_af:
        af = f"{extra_af},{af}"
    run_ffmpeg(
        ffmpeg,
        [
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
        ],
    )


def loop_segment_mp3(
    ffmpeg: str,
    src: str,
    dst: str,
    start: float,
    seg_dur: float,
    loop_times: int,
    extra_af: str,
    lufs: int,
) -> None:
    """Extract segment with fades, concatenate for seamless-ish loop."""
    import tempfile

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    fade_in = 2.4
    fade_out = 3.1
    af_base = (
        f"afade=t=in:st=0:d={fade_in},"
        f"afade=t=out:st={max(0.1, seg_dur - fade_out)}:d={fade_out}"
    )
    if extra_af:
        af_base = f"{extra_af},{af_base}"
    af = f"{af_base},{AMB_FILTER.format(lufs=lufs)}"

    with tempfile.TemporaryDirectory() as tmp:
        chunk = os.path.join(tmp, "chunk.mp3")
        run_ffmpeg(
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
            for _ in range(loop_times):
                f.write(f"file '{chunk.replace(chr(92), '/')}'\n")
        run_ffmpeg(
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


def main() -> None:
    ffmpeg = find_ffmpeg()
    print(f"ffmpeg: {ffmpeg}")
    ok = 0
    total = 0

    def job(fn):
        nonlocal ok, total
        total += 1
        try:
            fn()
            ok += 1
            print(f"  ok")
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED: {exc}", file=sys.stderr)

    # ---- BGM ----
    print("== BGM ==")

    def bgm_zen_tsukiyomi():
        src = find_src(SRC_ADDED, "harumachimusic-tsukiyomi")
        dst = os.path.join(DST_BGM, "zen_tsukiyomi.mp3")
        print(f"zen_tsukiyomi <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=120,
            extra_af="highpass=f=90,lowpass=f=12000",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_cyber_suspense():
        src = find_src(SRC_ADDED, "suspense-cyberpunk-375986")
        dst = os.path.join(DST_BGM, "cyber_suspense.mp3")
        print(f"cyber_suspense <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=8,
            duration=120,
            extra_af="highpass=f=80",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_astro_moon():
        src = find_src(SRC_ADDED, "you-are-alone-on-the-moon")
        dst = os.path.join(DST_BGM, "astro_alone_moon.mp3")
        print(f"astro_alone_moon <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=100,
            extra_af="lowpass=f=14000",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_astro_underscore():
        src = find_src(SRC_ADDED, "deep-space-signal-atmospheric-tension")
        dst = os.path.join(DST_BGM, "astro_deep_underscore.mp3")
        print(f"astro_deep_underscore <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=130,
            extra_af="lowpass=f=9000,highpass=f=60",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_urban_tension():
        src = find_src(SRC_ADDED, "silent-tension-336681")
        dst = os.path.join(DST_BGM, "urban_silent_tension.mp3")
        print(f"urban_silent_tension <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=85,
            extra_af="",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_urban_pursuit():
        src = find_src(SRC_ADDED, "silent-pursuit-336682")
        dst = os.path.join(DST_BGM, "urban_silent_pursuit.mp3")
        print(f"urban_silent_pursuit <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=5,
            duration=85,
            extra_af="",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_urban_shot():
        src = find_src(SRC_ADDED, "silent-shot-336680")
        dst = os.path.join(DST_BGM, "urban_silent_shot.mp3")
        print(f"urban_silent_shot <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=35,
            extra_af="",
            lufs=BGM_LUFS - 2,
            amb_filter=BGM_FILTER,
        )

    def bgm_magical_ethereal():
        src = find_src(SRC_ADDED, "ethereal-magic-173534")
        dst = os.path.join(DST_BGM, "magical_ethereal.mp3")
        print(f"magical_ethereal <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=95,
            extra_af="highpass=f=100",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_magical_orchestra():
        src = find_src(SRC_ADDED, "orchestra-of-magic-and-inspiration-174149")
        dst = os.path.join(DST_BGM, "magical_orchestra.mp3")
        print(f"magical_orchestra <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=10,
            duration=110,
            extra_af="lowpass=f=15000",
            lufs=BGM_LUFS,
            amb_filter=BGM_FILTER,
        )

    def bgm_magical_victory():
        src = find_src(SRC_ADDED, "magic-orchestra-of-inspiration-173538")
        dst = os.path.join(DST_BGM, "magical_victory.mp3")
        print(f"magical_victory <- {os.path.basename(src)}")
        export_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=75,
            extra_af="",
            lufs=BGM_LUFS - 1,
            amb_filter=BGM_FILTER,
        )

    for fn in [
        bgm_zen_tsukiyomi,
        bgm_cyber_suspense,
        bgm_astro_moon,
        bgm_astro_underscore,
        bgm_urban_tension,
        bgm_urban_pursuit,
        bgm_urban_shot,
        bgm_magical_ethereal,
        bgm_magical_orchestra,
        bgm_magical_victory,
    ]:
        job(fn)

    # ---- Ambient loops ----
    print("== Ambient ==")

    def amb_zen_leaves():
        src = find_src(SRC_ADDED, "soft-wind-leaves")
        dst = os.path.join(DST_AMB, "zen_wind_leaves.mp3")
        print(f"zen_wind_leaves <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            seg_dur=14,
            loop_times=4,
            extra_af="highpass=f=120,lowpass=f=9000",
            lufs=AMB_LUFS,
        )

    def amb_zen_bird():
        src = find_src(SRC_ADDED, "bird-sound-in-a-forest")
        dst = os.path.join(DST_AMB, "zen_bird_subtle.mp3")
        print(f"zen_bird_subtle <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            seg_dur=18,
            loop_times=3,
            extra_af="highpass=f=400,lowpass=f=5500,volume=0.35",
            lufs=AMB_LUFS - 2,
        )

    def amb_fireplace():
        src = find_src(SRC_ADDED, "fireplace-jim")
        for name in ("royal_fireplace.mp3", "magical_fireplace.mp3"):
            dst = os.path.join(DST_AMB, name)
            print(f"{name} <- {os.path.basename(src)}")
            loop_segment_mp3(
                ffmpeg,
                src,
                dst,
                start=30,
                seg_dur=55,
                loop_times=2,
                extra_af="lowpass=f=6000,highpass=f=80",
                lufs=AMB_LUFS,
            )

    def amb_cyber_deep():
        src = find_src(SRC_ADDED, "ambient-cyberpunk-cinematic-8411")
        dst = os.path.join(DST_AMB, "cyber_ambient_deep.mp3")
        print(f"cyber_ambient_deep <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=45,
            seg_dur=50,
            loop_times=2,
            extra_af="lowpass=f=2500,highpass=f=70,volume=0.75",
            lufs=AMB_DEEP_LUFS,
        )

    def amb_rain():
        src = find_src(SRC_ADDED, "rain-in-the-city")
        dst = os.path.join(DST_AMB, "urban_rain_city.mp3")
        print(f"urban_rain_city <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=2,
            seg_dur=42,
            loop_times=2,
            extra_af="lowpass=f=11000",
            lufs=AMB_LUFS,
        )

    def amb_wind_renorm():
        src = find_src(SRC_AMB, "風の音")
        dst = os.path.join(DST_AMB, "wind.mp3")
        print(f"wind <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            seg_dur=24,
            loop_times=2,
            extra_af="",
            lufs=AMB_LUFS,
        )

    def amb_forest_boost():
        src = find_src(SRC_AMB, "森の妖精")
        dst = os.path.join(DST_AMB, "forest.mp3")
        print(f"forest (boosted) <- {os.path.basename(src)}")
        loop_segment_mp3(
            ffmpeg,
            src,
            dst,
            start=0,
            seg_dur=12,
            loop_times=3,
            extra_af="volume=4.0,highpass=f=200",
            lufs=AMB_LUFS + 4,
        )

    for fn in [
        amb_zen_leaves,
        amb_zen_bird,
        amb_fireplace,
        amb_cyber_deep,
        amb_rain,
        amb_wind_renorm,
        amb_forest_boost,
    ]:
        job(fn)

    # ---- SFX ----
    print("== SFX ==")

    def sfx_zen_paper():
        src = find_src(SRC_ADDED, "pencil-29272")
        dst = os.path.join(DST_SFX, "japaneseLuxury", "paper_ui.wav")
        print(f"paper_ui <- {os.path.basename(src)}")
        export_wav(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=0.35,
            extra_af="highpass=f=200",
            lufs=-26,
        )

    def sfx_royal_bell():
        src = find_src(SRC_ADDED, "church-bells-194653")
        dst = os.path.join(DST_SFX, "westernLuxury", "accusation_unlock.wav")
        print(f"accusation_unlock (church bell) <- {os.path.basename(src)}")
        export_wav(
            ffmpeg,
            src,
            dst,
            start=0,
            duration=0.55,
            extra_af="lowpass=f=8000",
            lufs=-26,
        )

    for fn in [sfx_zen_paper, sfx_royal_bell]:
        job(fn)

    print(f"\nDone: {ok}/{total}")
    if ok != total:
        sys.exit(1)


if __name__ == "__main__":
    main()
