# ONI PIN 音響・色彩・演出 決定案 v1

> **スコープ**: Presentation / Audio / Visual / Map Icon / Theme のみ。ゲームロジックは変更しない。  
> **BGM方針**: 1世界観1曲ではなく、Title / Lobby / Match / Final / Result で役割を分ける。

## 実装ステータス（2026-06 最終統合）

| 世界観 | 音楽 | 状態 |
|--------|------|------|
| Royal Classic | `royal_sarabande` / `royal_larghetto` / `royal_queen_of_sheba` + `royal_fireplace` | **Implemented** |
| Zen Kyoto | `zen_tsukiyomi` + Ambient（wood / leaves / wind / bird） | **Implemented** |
| Cyber Night | `cyber`（Title）/ `cyber_suspense` + `cyber_ambient_deep` | **Implemented** |
| Astronomy | `astro_alone_moon` / `astro_deep_underscore` + beep テレメトリ | **Implemented** |
| Urban Horror | Silent 3曲 + `urban_rain_city` / `wind` | **Implemented** |
| Magical World | Ethereal / Orchestra / Victory + fireplace / forest | **Implemented** |
| Stealth Tactical | `tactical` + `arg_bad_radio` / comms | **Implemented**（現状維持） |
| Pop City | `pop` / `pop2` / `pop_city` | **Implemented**（現状維持） |

比較用フラグ:

- `WorldMusicProfileCatalog.astronomyUseLegacySpaceBgm` — `space.mp3` へ切替
- `WorldMusicProfileCatalog.royalLobbyUseSarabandeUndertone` — Lobby に Sarabande 極薄アンダートーン

---

## Implemented — 世界観別 最終音響構成

### 1. Zen Kyoto

| フェーズ | 音源 |
|----------|------|
| Title / Gallery / Lobby | `zen_tsukiyomi` |
| Match | BGM なし — `zen_wood_jungle` + `zen_wind_leaves` + `wind`（常時レイヤー） |
| Moment | `zen_bird_subtle`（極薄） |
| UI | `paper_ui`（Tap / Confirm / Dialog） |

ワンショット Ambient: **無効**（レイヤーと二重にならないよう）

### 2. Royal Classic

| フェーズ | 音源 |
|----------|------|
| Title / Gallery | `royal_sarabande` |
| Lobby / Match | `royal_larghetto`（Match は低ゲイン） |
| Victory | `royal_queen_of_sheba` |
| Ambient | `royal_fireplace`（常時）/ `royal_bell_indoor`（稀） |
| Unlock SFX | 教会ベル `accusation_unlock.wav` |

### 3. Cyber Night

| フェーズ | 音源 |
|----------|------|
| Title / Gallery | `cyber` |
| Lobby / Match | `cyber_suspense` |
| Deep Layer | `cyber_ambient_deep`（BGM ではなく空気） |
| Moment | `sonar` / `comms`（イベント時のみ） |

### 4. Astronomy

| フェーズ | 音源 |
|----------|------|
| Title / Gallery / Lobby | `astro_alone_moon` |
| Match / Danger | `astro_deep_underscore` |
| Telemetry | `beep`（短尺・Moment / ワンショットのみ、常時禁止） |
| 比較用 | `space.mp3` |

### 5. Urban Horror

| フェーズ | 音源 |
|----------|------|
| Title | `urban_silent_tension` |
| Lobby / Match | `urban_silent_pursuit` |
| Moment / Capture | `urban_silent_shot` |
| Ambient | `urban_rain_city`（ループ）+ `wind`（40–120s ワンショット） |

### 6. Magical World

| フェーズ | 音源 |
|----------|------|
| Title / Gallery | `magical_ethereal` |
| Lobby / Match | `magical_orchestra` |
| Victory | `magical_victory` |
| Ambient | `magical_fireplace` + `forest`（Moment） |

SE は派手さを抑えた音量係数。

### 7. Stealth Tactical / 8. Pop City

前回どおり。変更なし。

---

## Candidate — 未採用（音源探索停止、差し替え待ち）

| 世界観 | 用途 | 候補名 | 現状 |
|--------|------|--------|------|
| Cyber Night | Title/Gallery | Neon Synthwave Cyberpunk | `cyber` 維持 |
| Royal Classic | — | 追加 Handel / Dvořák 原盤 | 同梱 MP3 で代替済み |
| Astronomy | — | Telepathic Spheres 等 | `astro_*` 採用済み |
| 全般 | ui_back | 世界観別 back SE | 汎用 SE / 合成音 |

---

## 色彩・マップ・演出

（決定案 v1 本文どおり — `WorldPresentationCatalog` / `WorldMapIconColors` 参照）

Royal Classic 色トークン例:

| Token | Hex |
|-------|-----|
| Background | `#F6F1E7` |
| Brass | `#B89A4F` |
| Gold | `#D4AF37` |
| Wine | `#6D2138` |

Astronomy: **スキャンライン禁止**。星雲・銀河光のみ。

---

## 関連コード

- `lib/audio/world_music_profile_catalog.dart` — 世界観別レイヤー定義
- `lib/audio/audio_library.dart` — `BgmId` / `AmbientId` / `WorldAudio`
- `lib/audio/world_audio_director.dart` — フェーズ遷移・Gallery Preview・Victory 復帰
- `lib/audio/game_audio.dart` — ワンショット Ambient 40–120s・フェード
- `lib/theme/world_fx_profile.dart` — 世界観 SE 音量・アセット
- `tools/prepare_polish_audio.py` — 音源正規化・ループ生成
