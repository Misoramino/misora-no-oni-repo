import '../../../theme/world_profile.dart';

/// 個人設定シートの初期値（この端末）。
class PlayerPersonalSettingsInitial {
  const PlayerPersonalSettingsInitial({
    required this.displayName,
    required this.profile,
    required this.useBleScan,
    required this.trajectoryConsent,
    this.avatarImagePath,
  });

  final String displayName;
  final WorldProfile profile;
  final bool useBleScan;
  final bool trajectoryConsent;
  final String? avatarImagePath;
}

/// 「適用」後に画面へ反映する値。
class PlayerPersonalSettingsResult {
  const PlayerPersonalSettingsResult({
    required this.displayName,
    required this.profile,
    required this.useBleScan,
    required this.trajectoryConsent,
    this.avatarImagePath,
  });

  final String displayName;
  final WorldProfile profile;
  final bool useBleScan;
  final bool trajectoryConsent;
  final String? avatarImagePath;
}
