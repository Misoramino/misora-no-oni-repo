# 世界観 BGM 構成設計（Direction Pass）

ゲームロジックは変更しない。`GameAudio` / `WorldAudio` への実装は段階的に行う。

## 目的

1 曲ループだけでなく、**場面レイヤー**で世界観の没入感を上げる。

## レイヤー案

| レイヤー | 用途 | 現状 |
|---------|------|------|
| `menu` | タイトル・設定・戦績 | `playMenuBgm(profile)` |
| `lobby` | ルームロビー | menu と同一 |
| `preMatch` | ロスター・軌道・カウントダウン | BGM 停止 or menu |
| `match` | 通常プレイ | `playMatchBgm` + ambient |
| `climax` | 残り 10 分 / 告発解禁後 | 未実装（同一 BGM） |
| `victory` | 個人勝利リザルト | `SfxId.matchWin` のみ |
| `defeat` | 個人敗北リザルト | `SfxId.matchLose` のみ |

## 世界観 × 暫定 BGM（`WorldAudio.defaultBgm`）

| 世界観 | menu/match | 推奨専用曲（将来） |
|--------|------------|-------------------|
| Urban Horror | horror | 低 BPM・テープノイズ入り |
| Pop City | pop | 軽快ポップ |
| Cyber Night | cyber | シンセ・アルペジオ |
| Stealth Tactical | tactical | ミニマル・パーカッション |
| Magical World | magical | 古楽器・和音 |
| Astronomy | space | パッド・静寂 |
| Zen Kyoto | magical ⚠️ | **専用和風アンビエント**（禅・尺八寄り） |
| Royal Classic | space ⚠️ | **専用弦・オルガン** |

## 環境音（`WorldAudio.ambient`）

| 世界観 | ambient | 備考 |
|--------|---------|------|
| Zen Kyoto | wind（2026 Direction Pass で forest から変更） | Magical の forest と分離 |
| Royal Classic | wind | Horror と共有 — 将来 `marble_hall` 等を検討 |

## 実装フェーズ（次 IPA 後）

1. **P0**: Zen Kyoto / Royal Classic 専用 BGM 1 曲ずつ同梱
2. **P1**: `preMatch` で BGM ダック（-6dB）＋環境音のみ
3. **P2**: `climax` ステム（終盤 10 分でフィルター開く）
4. **P3**: リザルト専用 3〜5 秒スティング（勝利/敗北）

## 音量方針

- menu BGM: 現行 loudnorm 維持
- match + ambient: ambient は -24 LUFS 目安（`prepare_world_sfx.py` と同基準）
- moment SE（capture 等）は BGM より +3〜6 dB 相対で聞こえるよう `WorldFxProfile` 係数で調整済み
