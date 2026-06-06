# オーディオ素材の入れ方（フリー音源）

このフォルダに音声ファイルを置くだけで、アプリが自動で「本物の音」を使います。
ファイルが無いイベントは、コード合成音（`lib/audio/sfx_synth.dart`）に自動フォールバックします。

## 置き場所とファイル名

### 効果音（SE）: `assets/audio/sfx/`
ファイル名（拡張子なし）は以下のどれかにしてください。対応拡張子: `.wav` `.mp3` `.ogg` `.m4a`
（同名で複数拡張子があれば wav > mp3 > ogg > m4a の順で使われます）

| ファイル名 | 鳴る場面 |
|---|---|
| `ui_tap` | ボタン押下 |
| `ui_back` | 戻る |
| `ui_toggle` | トグル切替 |
| `ui_confirm` | 確定・決定 |
| `ui_error` | 入力エラー |
| `match_start` | 試合開始 |
| `match_win` | 勝利（ファンファーレ） |
| `match_lose` | 敗北 |
| `capture` | 捕獲の瞬間 |
| `eliminated` | 脱落 |
| `reveal` | 名前付き位置暴露 |
| `anon_reveal` | 匿名の位置暴露 |
| `skill_cast` | スキル発動 |
| `skill_ready` | スキル使用可能 |
| `denied` | 使用不可・クールダウン |
| `proximity_warning` | 鬼が近い（警告） |
| `proximity_danger` | 鬼が至近（危険） |
| `reward` | 報酬獲得 |
| `unlock` | アンロック |
| `confetti` | 紙吹雪・祝祭 |

例: `assets/audio/sfx/ui_tap.wav`

### BGM: `assets/audio/bgm/`
ループ再生されます。対応拡張子: `.mp3` `.ogg` `.wav` `.m4a`

| ファイル名 | シーン |
|---|---|
| `title` | タイトル画面 |
| `lobby` | ルームロビー／準備 |
| `match` | 試合中 |
| `result` | リザルト |

例: `assets/audio/bgm/title.mp3`

## おすすめのフリー音源（商用可・要ライセンス確認）

- 効果音: [効果音ラボ](https://soundeffect-lab.info/) / [GameSynth] / [Kenney Audio](https://kenney.nl/assets?q=audio)（CC0）
- BGM: [DOVA-SYNDROME](https://dova-s.jp/) / [魔王魂](https://maou.audio/) / [Incompetech](https://incompetech.com/)（CC BY）

CC BY 等の表示が必要なライセンスを使う場合は、クレジット表記をアプリ内（設定や About）に追加してください。

## 音量について
- 端末の「設定 → サウンド」で マスター/効果音/BGM 音量とミュートを調整できます。
- ファイルごとの音量差は、書き出し時にノーマライズ（-14 LUFS 目安）しておくと揃います。
