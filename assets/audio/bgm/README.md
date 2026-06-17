# BGM ここに置く

`title.mp3` などのファイル名で BGM を置くとループ再生されます。
ファイル名一覧は `../README.md` を参照。未配置ならそのシーンは無音です。

## Royal Classic（本採用・差し替え前提）

| ファイル | 役割 | 目標曲 |
|----------|------|--------|
| `royal_sarabande.mp3` | Title / Gallery / Final tension | Handel — Water Music: Sarabande |
| `royal_larghetto.mp3` | Lobby / Match（低音量）/ Lose | Dvořák — Serenade Op.22: IV. Larghetto |
| `royal_queen_of_sheba.mp3` | Victory / Accusation Success | Handel — Arrival of the Queen of Sheba |

現在同梱の Royal BGM は `音/` の Handel + Dvořák 音源から `tools/prepare_royal_bgm.py` で生成済み（loudnorm・ループクロスフェード）。
詳細は `docs/world_audio_visual_decisions.md`。
