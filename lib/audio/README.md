# Audio stack

```
UI / Screens
    └── WorldAudioDirector     … 画面・試合フェーズに応じた BGM 状態機械
            └── GameAudio      … レイヤー BGM / SE / 環境音 / レガシー単曲
                    └── BgmLayerEngine
```

## WorldAudioState 遷移（概要）

| From context | Typical `enter()` state |
|--------------|----------------------|
| Title | `title` |
| World gallery | `gallery` |
| Room lobby | `lobby` |
| Prep / countdown | `preMatchPresentation` → `matchCountdown` |
| Running match | `match` → `finalFiveMinutes` / `finalMinute` / `finalTenSeconds` |
| Proximity / danger | `danger` |
| Accusation | `accusationAvailable` → `accusationSequence` |
| Result | `resultVictory` / `resultLose` / `resultDraw` / `resultSpectator` |
| Replay screen | `replay` |
| Back to title | `returnTitle` |

`WorldAudioDirector.onProfileChanged` — 世界観切替（Presentation morph と同期利用）。

`WorldAudioDirector.onMatchTick` — 残り時間に応じた climax レイヤー（重複 enter 防止済み）。

## 設定

- `AudioSettings.layeredBgmEnabled` — 4 レイヤー BGM（推奨・既定 ON）
- OFF 時は `GameAudio.playMenuBgm` の単曲レガシーパス（後方互換）

## 関連

- `world_music_profile_catalog.dart` — 世界観別曲・レイヤー gain
- `world_fx_profile.dart` — SE 音量係数
- `docs/audio_credits.md` — クレジット
