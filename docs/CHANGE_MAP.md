# 変更箇所マップ（ピンポイント検証用）

「この領域を変えた」→「主に触るファイル」→「まず回すテスト」の対応表です。  
仕様を変えないリファクタでも、ここに載っているテストが通れば大きな退行に気づきやすいです。

## 必須（どの変更でも）

| 検証 | コマンド |
|------|----------|
| 静的解析 | `flutter analyze` |
| ユニットテスト | `flutter test` |

## 領域別マップ

### A. ゲーム定数・バランス（時間・CD・半径など）

| 主ファイル | 関連 |
|------------|------|
| `lib/game/game_config.dart` | 各種秒数・半径・上限 |
| `lib/game/game_state.dart` | 状態列挙・表示ラベル |
| `lib/features/game_map/match/match_tick_evaluator.dart` | エリア外ティック |
| `lib/features/game_map/match/game_map_match_controller.dart` | スキル tick → 効果 |

**テスト:** `flutter test test/match_tick_evaluator_test.dart`  
`flutter test test/game_map_match_controller_test.dart`

### B. プレイエリア・GeoJSON

| 主ファイル | 関連 |
|------------|------|
| `lib/game/play_area.dart` | 形状・距離 |
| `lib/game/polygon_area_resolver.dart` | 多角形歩行 |
| `lib/services/play_area_store.dart` / `play_area_slot_store.dart` | 永続化 |

**テスト:** `flutter test test/play_area_test.dart`  
`flutter test test/polygon_area_resolver_test.dart`

### C. ギミック生成・拾い・カメラ

| 主ファイル | 関連 |
|------------|------|
| `lib/game/generated_gimmicks.dart` | seed と密度 |
| `lib/features/game_map/match/gimmick_pickup_evaluator.dart` | 拾い判定 |
| `lib/game/game_config.dart` | 半径（[GAME_EVENT_AREAS.md](./GAME_EVENT_AREAS.md) と対応） |

**テスト:** `flutter test test/generated_gimmicks_test.dart`  
`flutter test test/gimmick_pickup_evaluator_test.dart`  
`flutter test test/camera_trigger_evaluator_test.dart`

### D. マップオーバーレイ・マーカー

| 主ファイル | 関連 |
|------------|------|
| `lib/features/game_map/map/game_map_overlay_builder.dart` | マーカー生成 |
| `lib/features/game_map/map/game_map_overlay_snapshot.dart` | スナップショット型 |
| `lib/features/game_map/visual/map_visual_controller.dart` | スタイル・LOD |
| `lib/theme/world_visual_pack_factory.dart`（等） | 世界観パック |

**テスト:** `flutter test test/game_map_overlay_builder_test.dart`  
`flutter test test/world_visual_pack_factory_test.dart`  
`flutter test test/map_replay_marker_helper_test.dart`

### E. リプレイ・記録・ジオユーティリティ

| 主ファイル | 関連 |
|------------|------|
| `lib/game/match_record.dart` | 保存形式 |
| `lib/services/match_recorder.dart` / `match_archive_store.dart` | 録画・読み出し |
| `lib/features/game_map/logic/map_geo_utils.dart` | 時計・方位など |

**テスト:** `flutter test test/match_record_test.dart`  
`flutter test test/map_geo_utils_test.dart`  
`flutter test test/trajectory_simplify_test.dart`

### F2. 告発・第二ゲーム・ロビーエリア

| 主ファイル | 関連 |
|------------|------|
| `lib/game/accusation_logic.dart` / `accusation_sites.dart` | 解禁・有効施設数 |
| `lib/game/accusation_block_logic.dart` | 本鬼による施設単位ブロック |
| `lib/game/facility_sabotage_logic.dart` / `spectral_territory_logic.dart` / `camera_shutdown_logic.dart` | 脱落後チャージ |
| `lib/game/elimination_aftermath_rule.dart` | 残響体 vs 鬼影分岐 |
| `lib/screens/game_map_screen.dart` | イベント配線・`lobby_play_area` |

**テスト:** `flutter test test/accusation_logic_test.dart`  
`flutter test test/accusation_sites_test.dart`  
`flutter test test/accusation_block_logic_test.dart`

### F3. 人狼・鬼軌跡・結界同期

| 主ファイル | 関連 |
|------------|------|
| `lib/game/werewolf_forced_schedule.dart` | 強制間隔・任意CD |
| `lib/game/oni_path_trail.dart` | 遅延軌跡 |
| `lib/sync/room_match_event.dart` | `CaptureZoneEventPayload.fromSkill` |
| `lib/features/game_map/match/match_runtime_state.dart` | `lockZone*` |

**テスト:** `flutter test test/werewolf_forced_schedule_test.dart`  
`flutter test test/oni_path_trail_test.dart`  
`flutter test test/match_balance_test.dart`  
`flutter test test/room_match_event_test.dart`

### F. オンライン（Firestore・ルーム）

| 主ファイル | 関連 |
|------------|------|
| `lib/sync/firestore_room_session.dart` | 参加・購読・イベント送信 |
| `lib/sync/room_match_event.dart` | イベント payload 解釈 |
| `lib/screens/room_lobby_screen.dart` | ロビー UI |
| `firestore.rules` | 権限（リポジトリの例を Console にデプロイ） |

**テスト:** `flutter test test/firestore_presence_contract_test.dart`  
`flutter test test/room_match_event_test.dart`  
`flutter test test/shared_match_snapshot_test.dart`  
`flutter test test/room_phase_test.dart`

### G. 近接・感染距離（GPS + BLE 補助）

| 主ファイル | 関連 |
|------------|------|
| `lib/features/game_map/match/match_geo_helpers.dart` | 距離・スケール |
| `lib/proximity/*.dart` | BLE / ハイブリッド |
| [BLE_PROXIMITY.md](./BLE_PROXIMITY.md) | 挙動の説明 |

**テスト:** `flutter test test/match_geo_helpers_test.dart`  
`flutter test test/proximity_merge_test.dart`

### H. 画面オーケストレーション（v2 で part 分割済み）

| 主ファイル | 注意 |
|------------|------|
| `lib/screens/game_map_screen.dart` | 状態フィールド・init/build・GPS・近接 |
| `lib/features/game_map/game_map_screen_index.dart` | **part 一覧の索引**（修正時はここから） |
| `game_map_screen.online_sync.dart` | Firestore イベント受信 |
| `game_map_screen.reveals_gimmicks.dart` | 暴露・ギミック |
| `game_map_screen.hud_experience.dart` | HUD・プリセット・第二ゲーム導入 |
| `game_map_screen.play_area.dart` | エリア編集・保存 |
| `game_map_screen.match_lifecycle.dart` | 試合開始/終了・ティック |
| `game_map_screen.accusation.dart` | 告発 |
| `game_map_screen.second_game.dart` | 脱落後（残響体/鬼影） |
| `game_map_screen.skills.dart` | スキル |
| `game_map_screen.overlay.dart` | 地図オーバーレイ |
| `lib/screens/app_launch_shell.dart` | 起動演出 → タイトル遷移 |
| `lib/screens/title_screen.dart` | 入口・Firebase 表示・**v3.0.0** |
| `lib/screens/room_lobby_screen.dart` | ロビー（非ホスト向けルール概要） |
| `lib/features/game_map/prep/prep_lobby_panel.dart` | 準備 UI（設定サマリ一行） |
| `lib/features/game_map/widgets/game_info_panel.dart` | HUD（フェーズ・イベント履歴） |

**テスト:** `flutter test test/hud_compact_line_test.dart`  
`flutter test test/hud_display_prefs_test.dart`  
`flutter test test/match_setup_summary_test.dart`  
`flutter test test/match_quick_preset_test.dart`  
`flutter test test/accusation_weight_test.dart`  
+ 上記 A〜G + 実機 [DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md)

### I. 起動ブランド・世界観スプラッシュ

| 主ファイル | 注意 |
|------------|------|
| `lib/screens/app_launch_shell.dart` | 図形ロゴ・効果音・ハンドオフ |
| `lib/widgets/themed_geometric_logo.dart` | 世界観別マーク |
| `lib/features/branding/launch_effect_overlay.dart` | 起動オーバーレイ |
| `lib/theme/world_launch_branding.dart` | 色・演出種別 |
| `assets/branding/app_icon.png` | `dart run flutter_launcher_icons` |

**テスト:** `flutter test test/world_launch_branding_test.dart`  
`flutter test test/launch_sound_synth_test.dart`

## `test/` 全ファイル早見（カバレッジの感覚）

| テストファイル | ざっくり中身 |
|----------------|--------------|
| `camera_trigger_evaluator_test.dart` | 監視カメラ半径 |
| `firestore_presence_contract_test.dart` | メンバー表示のパース |
| `game_map_match_controller_test.dart` | マッチコントローラ |
| `game_map_overlay_builder_test.dart` | オーバーレイ |
| `generated_gimmicks_test.dart` | ギミック決定性 |
| `gimmick_pickup_evaluator_test.dart` | 拾い・CD |
| `map_geo_utils_test.dart` | 時計・方位 |
| `map_replay_marker_helper_test.dart` | 再生マーカー種別 |
| `match_geo_helpers_test.dart` | 鬼距離・感染距離 |
| `match_quick_preset_test.dart` | 試合プリセット3択 |
| `match_setup_summary_test.dart` | 準備/ロビー設定サマリ |
| `accusation_weight_test.dart` | 告発重みモード |
| `match_role_mix_test.dart` | 役職ミックス |
| `player_progress_test.dart` | 進行・称号 |
| `match_record_test.dart` | 記録 JSON |
| `match_runtime_state_test.dart` | ランタイム状態リセット |
| `match_tick_evaluator_test.dart` | エリア外ティック |
| `play_area_test.dart` | エリア JSON |
| `polygon_area_resolver_test.dart` | 多角形 |
| `proximity_merge_test.dart` | 近接バンドマージ |
| `room_match_event_test.dart` | ルームイベント・`fromSkill` |
| `accusation_block_logic_test.dart` | 本鬼の告発ブロック |
| `oni_path_trail_test.dart` | 鬼遅延軌跡の表示帯 |
| `werewolf_forced_schedule_test.dart` | 強制鬼化間隔・任意CD |
| `facility_sabotage_logic_test.dart` | 鬼影・告発妨害チャージ |
| `room_phase_test.dart` | フェーズ文字列 |
| `shared_match_snapshot_test.dart` | 共有試合開始 |
| `trajectory_simplify_test.dart` | 軌跡間引き |
| `widget_test.dart` | プレースホルダ |
| `hud_compact_line_test.dart` | 一行 HUD 文言（すべて／単体） |
| `hud_display_prefs_test.dart` | HUD 設定デフォルト |
| `launch_sound_synth_test.dart` | 起動効果音 WAV |
| `world_launch_branding_test.dart` | 起動ブランド色 |
| `world_visual_pack_factory_test.dart` | 世界観パック |
