/// [GameMapScreen] の実装ファイル索引。
///
/// 画面本体は `lib/screens/game_map_screen.dart` にあり、
/// ドメイン別ロジックは `part` + `extension` で分割されています。
/// 機能を直すときは **下表の part を開く** のが最短です。
///
/// ## ファイル一覧
///
/// | ファイル | 主な責務 | 代表メソッド |
/// |---|---|---|
/// | `game_map_screen.dart` | 状態フィールド・init/build・GPS・近接 | `build`, `_acceptPosition` |
/// | `game_map_screen.online_sync.dart` | Firestore イベント受信 | `_onRemoteRoomMatchEvent` |
/// | `game_map_screen.reveals_gimmicks.dart` | 暴露・ギミック取得 | `_emitIdentifiedReveal` |
/// | `game_map_screen.hud_experience.dart` | HUD・プリセット・第二ゲーム導入 | `_recordMatchFeed` |
/// | `game_map_screen.play_area.dart` | エリア編集・保存 | `_hostApplySelectedPlayArea` |
/// | `game_map_screen.match_lifecycle.dart` | 試合開始/終了・ティック | `_startGame`, `_endGame` |
/// | `game_map_screen.accusation.dart` | 告発 | `_hostResolveAccusationAttempt` |
/// | `game_map_screen.second_game.dart` | 脱落後操作 | `_evaluateCameraJack` |
/// | `game_map_screen.skills.dart` | スキル・体投げ・近接 | `_activateFakeSkill`, `_activateBodyThrow` |
/// | `game_map_screen.overlay.dart` | 地図描画スナップショット | `_overlaySnapshot` |
///
/// ## 関連モジュール（part 外）
///
/// - 試合ランタイム状態: `match/match_runtime_state.dart`
/// - 地図マーカー描画: `map/game_map_overlay_builder.dart`
/// - カスタム設定 UI: `settings/game_custom_settings_sheet.dart`
/// - 告発重み・プリセット: `lib/game/accusation_weight.dart`, `match_quick_preset.dart`
library;
