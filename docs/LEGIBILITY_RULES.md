# UI 可読性ルール（LEGIBILITY）

世界観（8プロファイル）ごとに背景とパネルの明度が異なるため、**Theme の既定色だけに頼らない** ことが製品品質の前提です。

## 原則

**黒文字と白文字を同じ画面で使うのは意図的な設計**です（暗いグラデーション背景＋明るいカード／箇条書き）。可読性は次の組み合わせで担保します。

| 置き場所 | 本文 | 補助 | ラッパー |
|----------|------|------|----------|
| グラデーション背景（スキャフォールド） | `worldBodyOnScaffold` | `worldMutedOnScaffold` | `WorldScaffoldThemed` |
| Card / ダイアログ / チップ（明パネル） | `worldBody` | `worldMuted` | `WorldPanelThemed` |
| 任意の半透明・バナー背景 | `worldTextOn(bg)` | `worldMutedOn(bg)` | — |
| 図解・CustomPaint | `diagramLegibility()` | — | 親は `WorldPanelThemed` 推奨 |

### やってはいけないこと

- `Theme.of(context).colorScheme.onSurface` を画面コードで直接使う（`AppThemeFactory` はパネル向け `onSurface`）
- 暗いスキャフォールド上で `worldBody`（= パネル用の暗色文字）を使う
- 明パネル上で `worldBodyOnScaffold`（= スキャフォールド用の明色文字）を使う
- 図解で `colorScheme.outline` / `tertiary` に依存する（世界観で薄くなる）

## 壊れやすい世界観

| プロファイル | リスク |
|--------------|--------|
| **禅京都** (`japaneseLuxury`) | 暗背景 + 明パネル — 取り違え最多 |
| **マジカル** (`magical`) | 同上 |
| **ロイヤル** (`westernLuxury`) | 明背景 + 明パネル — アクセントが薄いと読みにくい |
| **ポップ** (`sport`) | 明背景 — 比較的安全 |

ホラー / サイバー / ステルス / 天文は暗パネルが多く、上記ミスは起きにくい（HUD・地図オーバーレイは別系統）。

## 自動チェック

```bash
# 静的監査（アンチパターン grep）
dart run tools/audit_legibility.dart

# トークンコントラスト（8世界観）
flutter test test/presentation_completion_pass_test.dart

# 画面・図解 widget test
flutter test test/legibility_screens_test.dart

# 同一画面でのスキャフォールド色＋パネル色（8世界観）
flutter test test/dual_text_legibility_test.dart
```

リリース前は上記 3 つ + 下記実機チェックを推奨。

## 新規画面を足すとき

1. 背景直置き → `WorldScaffoldThemed`
2. Card / リストタイル → `WorldPanelThemed` または色を明示
3. 図 → `diagramLegibility()` とセマンティック固定色（赤=鬼など）
4. `dart run tools/audit_legibility.dart` を通す
5. 該当画面を `legibility_screens_test.dart` に 1 ケース追加

## 関連ファイル

- `lib/presentation/world/world_presentation_pack.dart` — `textOn` / `mutedOn`
- `lib/presentation/world/world_legibility.dart` — BuildContext 拡張
- `lib/presentation/world/world_ui_helpers.dart` — `WorldScaffoldThemed` / `WorldPanelThemed`
- `lib/theme/map_hud_contrast.dart` — HUD・図解トークン
