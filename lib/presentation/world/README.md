# World presentation layer

UI の世界観は **ゲームロジックと分離** しています。

```
Theme (Material)
    └── WorldProfileTheme          … ThemeExtension<WorldProfile>
            └── WorldPresentationPack   … 色・タイポ・ボタン形状（catalog）
                    └── WorldStudioIdentity … コピー・モーション（studio catalog）
                            └── Widgets (WorldScaffold, WorldChip, WorldButton, …)
```

## 読み取り

```dart
final pack = context.worldPresentation;  // WorldPresentationPack
final profile = context.worldProfile;
```

または `WorldPresentationCatalog.of(profile)`。

## 色の約束

| Getter | 用途 |
|--------|------|
| `textOnScaffold` / `mutedOnScaffold` | グラデーション背景上 |
| `textOnPanel` / `mutedOnPanel` | Card / Dialog / HUD パネル |
| `buttonLabelOnAccent` | アクセント塗りボタン |
| `readableOnScaffold(color)` | 暗背景に薄い accent を載せるとき |

`AppThemeFactory`（`lib/theme/`）は Material `ThemeData` のベース。世界観色は `WorldPresentationPack` が主。

## 主要ウィジェット

- `WorldScaffold` — 背景 + morph + entry reveal
- `WorldProfileMorphOverlay` — 世界観クロスフェード
- `WorldIconFrame` — ギャラリー / チップ用アイコン枠
- `world_ui_helpers.dart` — `showWorldSnackBar`, `showWorldSheet`
