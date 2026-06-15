# 世界観別 SFX（World FX Pack）

各世界観フォルダに短い効果音を置く。パス形式:

```
assets/audio/sfx/worlds/<WorldProfile.name>/<base>.<ext>
```

`<WorldProfile.name>` は `horror` / `sport` / `sciFi` / `arg` / `magical` / `astronomy`（`WorldProfile.storageName`）。

## ファイル名（ベース名）

| ベース名 | 用途 |
|---------|------|
| `ui_tap` | UIタップ |
| `ui_back` | 戻る・スキップ |
| `reveal` | 名前付き暴露 |
| `anon_reveal` | 匿名痕跡 |
| `capture` | 捕獲 |
| `countdown` | カウントダウン tick / 開始 |
| `transition` | 画面遷移 |
| `accusation_unlock` | 告発解禁 |

拡張子: `wav` / `mp3` / `ogg` / `m4a`（先に見つかったものを使用）。

## フォールバック順

1. `worlds/<profile>/<base>.<ext>`
2. `assets/audio/sfx/<SfxId.asset>.<ext>`（グローバル）
3. `SfxSynth` コード合成音

## 採用基準

- 0.1〜1.2 秒の短い音を優先
- UI 音は耳に刺さらない音量
- 暴露は分かるがうるさすぎない
- 捕獲はやや強めでよい（500〜900ms 演出と合わせる）
- ループ音は使わない

ライセンスは `docs/audio_credits.md` に記録すること。

## P0 優先（外部ファイルを置くなら先にここ）

```
worlds/sciFi/ui_tap.wav
worlds/sciFi/reveal.wav
worlds/sciFi/transition.wav
worlds/magical/ui_tap.wav
worlds/magical/reveal.wav
worlds/magical/transition.wav
worlds/horror/ui_tap.wav
worlds/horror/reveal.wav
worlds/horror/transition.wav
```

未配置でもビルド・再生は問題ない（合成音にフォールバック）。

## P0 同梱済み（2026-06-06）

sciFi / magical / horror の `ui_tap` / `reveal` / `transition` は Mixkit 音源を同梱。

## P1 同梱済み（2026-06-06）

sport / arg / astronomy の `ui_tap` / `reveal` / `transition` も同梱済み。

クレジット: `docs/audio_credits.md`

新しい世界観フォルダを追加したら `pubspec.yaml` の `assets:` に
`assets/audio/sfx/worlds/<worldId>/` を追記すること。
