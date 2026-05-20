/// ゲーム画面で使う SharedPreferences キー。
abstract final class GameMapPrefs {
  static const trajectoryConsent = 'trajectory_consent_default';
  static const eliminationAftermathRule = 'elimination_aftermath_rule_v1';
  static const useBleScanProximity = 'use_ble_scan_proximity_v1';
  static const avatarImagePath = 'player_avatar_path_v1';
  static const worldProfile = 'world_profile_v1';
  /// ギミック個数倍率（ホスト、試合開始時に matchStart にも保存）。
  static const gimmickDensity = 'gimmick_density_v1';
}
