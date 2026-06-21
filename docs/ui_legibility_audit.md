# UI 可読性監査（全世界観・全 UI）

調査日: 2026-06-16  
目的: 文字・図・アイコン・チップ・表・凡例が表示される **全 Widget** を列挙し、8 世界観それぞれで可読性を評価する。

## 評価記号

| 記号 | 意味 |
|------|------|
| ✅ | 世界観トークン / `MapHud*` / `WorldLegibility` 経由で問題なし（または自動テストで確認済み） |
| ⚠️ | `ColorScheme.onSurfaceVariant` 等の Material 直参照。世界観によっては補助文・図が薄い |
| 🔧 | 今回の監査サイクルで修正済み |
| 📋 | 図・CustomPaint 系。線/塗りが背景に溶けるリスクあり |

## 世界観トークン（SSOT）

| 用途 | トークン | 定義 |
|------|----------|------|
| スキャフォールド背景 | `scaffoldGradient` | `WorldPresentationPack` |
| パネル背景 | `panelSurface` / `panelSurfaceOpaque` / `panelOnScaffold` | 同上 |
| 本文 | `textOnScaffold` / `textOnPanel` | 同上 |
| 補助文 | `mutedOnScaffold` / `mutedOnPanel` | 同上 |
| アクセント | `accentOnScaffold` / `accent` | 同上 |
| ボタンラベル | `buttonLabelOnAccent` | 同上 |
| 準備 HUD | `MapHudPrepLegibility` | `theme/map_hud_contrast.dart` |
| 試合 HUD パネル | `MapHudContrast.runningControlPanelBg` 等 | 同上 |
| ショートカット | `context.worldBody` 等 | `presentation/world/world_legibility.dart` |

---

## 1. タイトル画面

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `TitleScreen` | 見出し・副題・CTA | ⚠️ | `onSurfaceVariant` 2 箇所。`WorldScaffold` 上 |
| `LaunchEffectOverlay` | 起動演出・図形 | 📋 | 世界観別ネオン/VHS。文字は演出専用 |
| `TitleAmbientOverlay` | 粒子 | 📋 | 装飾のみ |
| `OniPinMarkPainter` | ロゴ | 📋 | ブランド固定色 |
| `BrandLogo` / `ThemedGeometricLogo` | ロゴ | ✅ | 固定パレット |

---

## 2. ルームロビー

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `RoomLobbyScreen` | ルーム名・参加者・世界観 | ⚠️ | `WorldScaffold` + 一部 `colorScheme` 直参照 |
| `WorldChip` | 世界観チップ | 🔧 | トークン化済み |
| `MemberConnectionLabel` | 接続状態 | ⚠️ | sync 層。要 HUD トークン化 |

---

## 3. 準備画面（GameMap waiting）

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `PrepLobbyPanel` | ルール・開始ボタン | ✅ | `MapHudPrepLegibility` 使用 |
| `PrepPlayAreaHub` | マップ/プレビュー/編集タイル | ✅ | `leg.*` トークン |
| `PrepSummaryTile` | 設定サマリー | ⚠️ | `onSurfaceVariant` |
| `PrepPersonalTile` | 個人設定入口 | ✅ | legibility 経由 |
| `LobbyRulesSummaryCard` | ルール概要 | ⚠️ | 補助文 |
| `PrepPlayAreaCollapsedPreview` | エリア形状 | ⚠️📋 | 文字 + 形状プレビュー |
| `PrepMapPreviewPanel` | 地図プレビュー | ⚠️ | |
| `PrepMapModeFab` | 閲覧/プレビュー/編集 | ⚠️ | `primaryContainer` / `onSurfaceVariant` |
| `PrepMapToolsPanel` | マップツール | ⚠️ | |
| `PrepMapBottomPanel` | 下部パネル | ⚠️ | |
| `AreaEditorCard` | エリア編集 | ⚠️ | |
| `PlayAreaShapePreview` | 図形 | 📋 | 世界観非連動の線色 |
| `MatchPlayabilityHints` | ヒント | ✅ | |
| `GameMapScreen` AppBar | タイトル「マップ」等 | 🔧 | 試合開始演出中はマップ表記を非表示 |
| 試合開始検証 | プレイエリア | 🔧 | 準備入室時の警告を廃止。開始ボタン時のみ具体理由 |

---

## 4. プリセット選択

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `MatchQuickPresetPicker` | プリセット一覧 | ⚠️ | `game_custom_settings_sheet` 内 |
| `GameCustomSettingsSheet` | カスタムルール | ⚠️ | チップ・補助文多数 |

---

## 5. 個人設定

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `PersonalSettingsScreen` | 名前・アバター・世界観 | ⚠️ | `Theme(AppThemeFactory)` プレビューあり。補助文要確認 |
| `WorldGalleryScreen` / `WorldSelectionSheet` | ギャラリー | 🔧 | 英語 CTA + 日本語副題 |

---

## 6. 設定ハブ / ガイドハブ

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `SettingsHubSheet` | 設定入口 | 🔧 | `showWorldSheet` + `WorldThemed` |
| `GuideHubSheet` | ガイド入口 | 🔧 | 同上 |
| `AudioSettingsSheet` | 音量・試聴 | ⚠️ | `onSurfaceVariant` 8 箇所 |
| `OnboardingReplaySheet` | かんたんガイド | 🔧 | |
| `DataManagementScreen` | データ管理 | ⚠️ | |

---

## 7. 各種ダイアログ

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `AppDialog` | 共通ダイアログ | 🔧 | `panelSurfaceOpaque` / `textOnPanel` |
| `ConfirmDialog` | 確認 | ⚠️ | |
| `RoleBriefingDialog` | 役職説明（試合開始） | 🔧 | pack トークン + 役職アクセント |
| `roleBriefingBlock` | 遊び方内役職 | 🔧 | |
| `showMatchStartPlayAreaBlockDialog` | 開始不能理由 | 🔧 | 具体メッセージ（距離 m 等） |
| `LocationPermissionPrompt` | 位置情報 | ⚠️ | |
| `TutorialEntry` ピッカー | チュートorial 選択 | 🔧 | |

---

## 8. BottomSheet

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `showWorldSheet` | 共通枠 | 🔧 | グラデーション + `WorldThemed` |
| `HowToPlaySheet` | 遊び方 | 🔧 | |
| `AccusationSheet` | 告発 | 🔧 | legibility |
| `GameCustomSettingsSheet` | ルール | ⚠️ | |
| `HowToPlaySheet` / `HowToPlayScreen` | ガイド | 🔧 | `WorldScaffold` |

---

## 9. HUD（試合中）

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `GameInfoPanel` | タイマー・エリア・情報 | ⚠️ | `MapHudContrast.infoPanelSurface` 部分使用。`scheme.primary` 残存 |
| `GameControlPanel` | スキル列 | ⚠️ | `onSurfaceVariant` on 試合中パネル |
| `SkillActionButton` | スキルボタン | ⚠️ | `surfaceContainerHighest` / `onSurfaceVariant` |
| `SkillTimerHud` | スキル CD | ⚠️ | |
| `CooldownChip` | CD チップ | ⚠️ | |
| `HudCompactLine` | 一行 HUD | ⚠️ | |
| `HudMarqueeText` | マーキー | ⚠️ | |
| `GameInlineStatusBadge` | ステータス | ⚠️ | |
| `MatchEventFeedBanner` | イベント | ⚠️ | |
| `SecondGameIntroOverlay` | 第二ゲーム導入 | ⚠️ | |
| `EliminationSupportBar` | 脱落後 | ⚠️ | |
| `GhostSpectatorBar` | 観戦 | ⚠️ | |
| `RoomInspectorBar` | インスペクタ | ⚠️ | |
| `DiagnosticsCard` | デバッグ | ⚠️ | testMode のみ |
| `MapLayerToggleStrip` | レイヤーチップ | ⚠️ | FilterChip — Material テーマ依存 |
| `WorldMomentBanner` | モーメント | ⚠️ | |

---

## 10. マップ上オーバーレイ

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `GameMapOverlayBuilder` | ピン・円・痕跡 | 📋 | `WorldProfileTokens` 色。世界観別 |
| `WorldMapAtmosphere` | 雰囲気 | 📋 | |
| `WorldMapThemePainters` | 地図装飾 | 📋 | sciFi/horror 等で線が薄い可能性 |
| `SkillMapPlacementLayer` | 配置 UI | ⚠️ | |
| `VhsOverlay` / `RevealNoiseOverlay` | 演出 | 📋 | |
| `MapsApiKeyBanner` | API キー警告 | ⚠️ | |
| `PlayAreaOrbitCinema` | AREA SCAN | 🔧 | 演出中 AppBar「マップ」と重ならないよう AppBar 側で非表示 |
| `MatchStartRosterOverlay` | 参加者 | 🔧 | pack トークン |
| `MatchStartCountdownOverlay` | カウントダウン | ⚠️ | 要世界観別確認 |
| `WorldPhaseFlash` | フラッシュ | 📋 | |

---

## 11. 告発 UI

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `AccusationSheet` | 告発フロー | 🔧 | |
| `game_map_screen.accusation.dart` | 告発ロジック+UI | ⚠️ | シート外トースト等 |

---

## 12. 情報屋 UI

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `GameInfoPanel` intel 行 | 鬼情報 | ⚠️ | 同上 |
| `HowToPlayDiagrams` / `IntroCluesDiagram` | 図解 | 📋⚠️ | ガイド側は 🔧、HUD 内図は未 |

---

## 13. スキル UI

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `SkillActionButton` | ボタン | ⚠️ | 優先度高 |
| `SkillTimerHud` | タイマー | ⚠️ | |
| `game_map_screen.skills.dart` | スキル配置 | ⚠️ | `onSurfaceVariant` |
| `SkillMapPlacementLayer` | マップ配置 | ⚠️ | |

---

## 14. チュートリアル

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `TutorialSandboxScreen` | サンドボックス | 🔧 | `WorldScaffold` |
| `SecondGameTutorialScreen` | 脱落後 | 🔧 | `WorldScaffold` |
| `TutorialInstructionBanner` | 指示 | 🔧 | |
| `TutorialFinishPanel` | 完了 | 🔧 | |
| `_ArenaPainter`（両 screen） | 簡易図 | 📋 | 固定 `colorScheme` — 和風/洋館で線が薄い可能性 |

---

## 15. 遊び方ガイド

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `HowToPlayGuideBody` | 本文 | ✅ | |
| `GuideHeaderCard` | ヘッダ | 🔧 | |
| `GuideCard` | カード | 🔧 | |
| `GuideSectionWidget` | 章 | 🔧 | |
| `GuideSpecTable` | 表 | 🔧 | |
| `GuideSectionIndex` | 章索引チップ | 🔧 | |
| `GuideDiagramSlot` | 図枠 | 🔧 | |
| `GuideDiagramViews` | 図解本体 | 🔧 | |
| `GuideYourRoleCard` | 役職 | 🔧 | |
| `GuideDetailExpansion` | 詳細 | ✅ | |
| `GuideRelatedLinks` | 関連リンク | ✅ | |
| `HowToPlayDiagrams` | マップ系図 | 📋⚠️ | 一部 Material 色残存 |

---

## 16. 役職説明

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `RoleBriefingDialog` | 試合開始 | 🔧 | |
| `roleBriefingBlock` | ガイド内 | 🔧 | |
| `MatchStartRosterOverlay` | ロスター | 🔧 | |

---

## 17. 試合結果

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `MatchResultScreen` | リザルト | ⚠️ | `WorldScaffold` + 一部 `onSurfaceVariant` |
| `MatchResultCopy` / hints | コピー | ✅ | テキストのみ |

---

## 18. リプレイ

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `MatchReplayScreen` | 再生 UI | ⚠️ | チップ・タイムライン |
| `MatchFlowTimeline` | タイムライン | ⚠️ | 図 + 文字 |
| `ReplayDirector` | 制御 | — | ロジック |

---

## 19. ギャラリー

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `AreaGalleryScreen` | エリアギャラリー | ⚠️ | |
| `WorldGalleryScreen` | 世界観ギャラリー | 🔧 | |
| `WorldIconFrame` | アイコン枠 | ✅ | テストあり |

---

## 20. コーチマーク

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `CoachMarks` | オーバーレイ説明 | 🔧 | pack トークン |
| `WelcomeFlow` | 初回スライド | 🔧 | `WorldScaffold` |
| `MatchStructureGuide` | 試合構造 | 🔧 | |
| `OfflinePracticeIntro` | オフライン案内 | ⚠️ | |
| `GuideBulletList` | 箇条書き | ⚠️ | |

---

## 21. その他全画面

| Widget / ファイル | 表示内容 | 状態 | 備考 |
|-------------------|----------|------|------|
| `ProgressScreen` | 実績 | ⚠️ | |
| `AppLaunchShell` | 起動 | ✅ | ローディングのみ |
| `LaunchHandoff` | ハンドオフ | ✅ | |

---

## 自動テスト（現状）

`test/presentation_completion_pass_test.dart` — 8 世界観中 5 プロファイルで `textOnPanel` / `textOnPanelOverScaffold` のコントラスト比を検証。  
**未カバー**: horror / sciFi / astronomy のパネルテスト、HUD・図・CustomPaint。

---

## オンライン / オフライン統合方針

- UI コードは **共有**（`GameMapScreen` 単一実装）。分岐は `_isOnlineFirestore` / `_isHost` のみ。
- 可読性トークンも共有。今回の試合開始検証 `_validatePlayAreaForMatchStart()` は両モード同一。
- 準備画面の距離警告: 入室時 GPS フックを **削除**。開始ボタンのみ。

---

## 優先修正キュー（残タスク）

1. **P0 HUD**: `GameInfoPanel`, `GameControlPanel`, `SkillActionButton` → `MapHudContrast` + `WorldPresentationPack` 完全移行
2. **P1 準備マップ系**: `PrepMapModeFab`, `PrepMapToolsPanel`, `PrepSummaryTile`
3. **P2 設定系**: `AudioSettingsSheet`, `PersonalSettingsScreen`, `GameCustomSettingsSheet`
4. **P3 図解**: `HowToPlayDiagrams`, チュートorial `_ArenaPainter` — 線色を `worldAccentReadable` / 世界観 tokens へ
5. **P4 テスト拡張**: 全 8 世界観 × パネル/HUD コントラスト比の自動化

---

## 検索コマンド（再監査用）

```bash
# Material 直参照（要レビュー）
rg "onSurfaceVariant|primaryContainer|surfaceContainerHighest" lib/

# 世界観トークン使用箇所
rg "worldMuted|worldBody|worldAccentReadable|MapHudPrepLegibility|textOnPanel" lib/

# 図・描画
rg "CustomPaint|Canvas|\.painter:" lib/
```
