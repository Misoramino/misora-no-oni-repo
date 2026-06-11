/// ゲーム画面で使う SharedPreferences キー。
abstract final class GameMapPrefs {
  static const trajectoryConsent = 'trajectory_consent_default';
  static const eliminationAftermathRule = 'elimination_aftermath_rule_v1';
  static const useBleScanProximity = 'use_ble_scan_proximity_v1';
  static const avatarImagePath = 'player_avatar_path_v1';
  static const worldProfile = 'world_profile_v1';
  /// 試合中 HUD 一行表示に載せる情報（intel / status / condition / all）。
  static const hudCompactLineSlot = 'hud_compact_line_slot_v1';
  static const hudShowIntelLine = 'hud_show_intel_line_v1';
  static const hudShowStatusLine = 'hud_show_status_line_v1';
  static const hudShowConditionLine = 'hud_show_condition_line_v1';
  /// 地図マーカー基準サイズ倍率（0.65〜1.5、既定 1.0）。
  static const mapMarkerIconScale = 'map_marker_icon_scale_v1';
  /// ギミック個数倍率（ホスト、試合開始時に matchStart にも保存）。
  static const gimmickDensity = 'gimmick_density_v1';
  /// ランダム割当の方式（'random' / 'counts'）。
  static const roleAssignMode = 'role_assign_mode_v1';
  /// 役職人数指定モードの鬼の人数。
  static const roleOniCount = 'role_oni_count_v1';
  /// 役職人数指定モードの人狼の人数。
  static const roleWerewolfCount = 'role_werewolf_count_v1';
  /// 告発の重み（instantWin / eliminateOni / points）。
  static const accusationWeight = 'accusation_weight_v1';
  /// ホスト向けプリセット3択を出したルームID（再表示防止）。
  static const hostQuickPresetPromptRoom = 'host_quick_preset_prompt_room_v1';
  /// 試合開始のロスター・オービットを省略（カウントダウンは維持）。
  static const shortMatchStartCeremony = 'short_match_start_ceremony_v1';
  /// ルームロビーへ行く前の説明ダイアログを省略。
  static const skipLobbyNavHint = 'skip_lobby_nav_hint_v1';
  /// オフライン準備の試合時間（秒）。オンライン試合中はホスト設定が優先。
  static const matchDurationSeconds = 'match_duration_seconds_v1';
}
