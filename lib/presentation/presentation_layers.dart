/// ONI PIN — Presentation 層の責務マップ（ロジック・同期とは分離）。
///
/// ## Audio (`lib/audio/`)
/// - [WorldAudioDirector]: 画面フェーズごとの BGM / レイヤー遷移
/// - [GameAudio]: SFX・レイヤー再生の実体
/// - [WorldMusicProfileCatalog]: 世界観別トラック定義
///
/// ## Replay (`lib/features/game_map/replay/`, `match_replay_screen.dart`)
/// - [ReplayDirector]: 視点・軌跡演出・カメラ判断
/// - [ReplayEventCues]: イベントと SE / フラッシュの同期
/// - [MatchReplayLatestFetch]: リザルト直後の最新アーカイブ取得
/// - [MatchArchiveMerger]: 分散アーカイブの統合
///
/// ## World Presentation (`lib/presentation/world/`)
/// - [WorldPresentationCatalog]: 8 世界観の UI パック
/// - [WorldIconFrame]: アイコン枠・影の差分
/// - [WorldAmbientPainter]: 画面粒子（控えめな生活感）
///
/// ## Theme (`lib/theme/`)
/// - [WorldProfileTokens]: マップ色・HUD
/// - [WorldFxProfile]: 瞬間 SE 音量・フラッシュ種別
///
/// ## Timeline (`lib/features/game_map/widgets/match_flow_timeline.dart`)
/// - 試合イベントの時系列表示（リザルト / リプレイ共有）
///
/// ## Notifications (`lib/services/resume_crisis_summary.dart` 等)
/// - バックグラウンド復帰時の要約（ゲーム判定は変更しない）
library;
