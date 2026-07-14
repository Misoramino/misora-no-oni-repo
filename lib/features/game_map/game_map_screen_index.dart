/// [GameMapScreen] の実装ファイル索引（2026-07 整理完了ベースライン）。
///
/// 画面本体は `lib/screens/game_map_screen.dart`。
/// ドメイン別ロジックは `part` + `extension`。直すときは **下表の part** を開く。
///
/// ルール数値・装備スキル文案の一次ソース:
/// `lib/game/game_config.dart` / `lib/game/skill_reference.dart`
///
/// ## part 一覧（15 + 本体）
///
/// | ファイル | 責務 |
/// |---|---|
/// | `game_map_screen.dart` | 状態フィールド（セクション分け済）・init/build・GPS |
/// | `online_sync.dart` | Firestore **受信**ディスパッチ |
/// | `match_events.dart` | 試合イベント **送信**・定期匿名・reveal/gimmick publish |
/// | `reveals_gimmicks.dart` | 暴露・ギミックの**ローカル**判定 |
/// | `hud_experience.dart` | HUD・トースト・条件文 |
/// | `play_area.dart` | エリア編集・保存・開始時寄せ |
/// | `match_lifecycle.dart` | 試合開始/終了・メインティック |
/// | `accusation.dart` | 告発 UI・解禁・解決 |
/// | `second_game.dart` | 残響体／鬼影 |
/// | `skills.dart` | 装備スキル・体投げ・人狼・偽位置 |
/// | `capture_zone.dart` | 捕獲結界の配置・bound |
/// | `overlay.dart` | 地図オーバーレイ組み立て |
/// | `host_light.dart` | ホスト不通時の救済 |
/// | `prep_sync.dart` | 準備ロビー・再開オンボーディング |
/// | `presentation.dart` | 開始演出 |
/// | `rejoin.dart` | 進行中試合への再参加 |
///
/// ## 用語
///
/// - `lockZone*` … 接触拘束 or 捕獲結界（`lockZoneFromSkill`）
/// - `capture_zone_*` … スキル結界の Firestore イベント
/// - `hunter` / wire `oni`|`hunter` … `MemberRoleWire`
///
/// ## 意図的にこのベースラインで止めること
///
/// - `screens/` の物理移動（God State のラベル付け直しはしない）
/// - `lockZone*` フィールドの大規模リネーム（ワイヤ互換のため）
/// - 告発 publish の完全サービス化（分岐は `accusation_outcome` 済）
library;
