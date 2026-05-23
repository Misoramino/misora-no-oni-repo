class GameConfig {
  /// 本番想定（10分）。短い検証は [debugMatchDurationSeconds]。
  static const int matchDurationSeconds = 600;

  static const int debugMatchDurationSeconds = 180;

  static const double captureDistanceMeters = 35;
  static const double scaledTouchRadiusMinMeters = 35;
  static const double scaledTouchRadiusMaxMeters = 95;
  static const double scaledTouchRadiusAreaRatio = 0.08;
  static const int touchLockRequiredSeconds = 4;
  static const int touchLockRunnerNoticeSeconds = 3;
  static const int touchLockDurationSeconds = 18;
  static const double warningDistanceMeters = 120;
  static const double dangerDistanceMeters = 70;

  static const double playAreaRadiusMeters = 500;
  static const int outsideAreaGraceSeconds = 8;
  static const double outsideAreaGraceMeters = 25;

  static const double gpsJumpIgnoreMeters = 120;
  static const int gpsJumpIgnoreWindowSeconds = 2;

  // Phase 2 prep: map gimmicks
  static const double safeZoneRadiusMeters = 40;
  static const int safeZoneMinCount = 1;
  static const int safeZoneMaxCount = 5;
  static const int safeZoneMaxCharges = 2;
  static const int safeZoneChargeCooldownSeconds = 25;
  static const int safeZoneRespawnSeconds = 40;

  static const double infoBrokerRadiusMeters = 30;
  static const int infoBrokerMinCount = 1;
  static const int infoBrokerMaxCount = 4;
  static const int infoBrokerCooldownSeconds = 35;
  static const int infoBrokerRespawnSeconds = 45;

  /// 鬼が情報屋を使ったあと、再使用まで（逃走者用より長め）。
  static const int oniInfoBrokerCooldownSeconds = 90;

  static const int periodicRevealIntervalSeconds = 40;

  // Phase 2: info-war tuning
  static const double commJammingZoneRadiusMeters = 75;
  static const int commJammingZoneMinCount = 1;
  static const int commJammingZoneMaxCount = 5;
  static const int commJammingCycleSeconds = 18;

  /// 「断片」鬼情報モードのフェーズ長（秒）。短すぎると情報が忙しく切り替わる。
  static const int fragmentedPhaseSeconds = 12;
  static const double cameraTriggerRadiusMeters = 18;
  static const int cameraMinCount = 4;
  static const int cameraMaxCount = 16;
  static const int fakeSkillCooldownSeconds = 75;
  static const int fakeSkillDurationSeconds = 14;
  /// 偽位置の初期スポーン: 現在地から進行方向へこの距離（m）。
  static const double fakePositionSpawnOffsetMeters = 28;
  /// 偽位置が進行方向へ流れる速さ（m/s）。
  static const double fakePositionDriftSpeedMps = 2.8;
  static const int fakeIntelRevealCooldownSeconds = 75;

  static const int werewolfTransformDurationSeconds = 20;
  static const int werewolfTransformCooldownSeconds = 90;
  static const double captureZoneRadiusMeters = 55;
  static const int captureZoneDurationSeconds = 16;
  static const int captureZoneCooldownSeconds = 80;
  static const double bodyThrowDistanceMeters = 90;
  static const int bodyThrowDurationSeconds = 12;
  static const int bodyThrowCooldownSeconds = 75;
  static const int bodyThrowMapTapWindowSeconds = 22;

  /// 体投げなどの短い操作ヒント（SnackBar）表示時間。
  static const int shortToastSeconds = 2;

  /// 試合中止投票の回答期限。
  static const int abortProposalTimeoutSeconds = 60;

  /// 鬼（hunter）位置を Firestore へ送る最小間隔。
  static const int hunterPositionPublishIntervalSeconds = 3;

  // Phase 2.5: infection and trace
  static const double infectionTriggerDistanceMeters = 38;
  static const int infectionExposureSeconds = 6;
  static const int infectionDurationSeconds = 22;
  static const int infectionRevealIntervalSeconds = 7;

  // Accusation (告発)
  static const int accusationMinPlayers = 3;
  static const double accusationUnlockTimeRatio = 0.6;
  static const int accusationUnlockMinElapsedSeconds = 300;
  static const double accusationFacilityRadiusMeters = 35;
  static const int accusationFacilityMinCount = 3;
  static const int accusationFacilityMaxCount = 5;

  // Camera jack (残響体)
  static const int cameraJackChargeSeconds = 15;
  static const int cameraJackPersonalCooldownSeconds = 100;
  static const int cameraJackMatchLimit = 5;
  static const double cameraJackSiteRadiusMeters = 28;

  /// ハッカー: 鬼の向き表示に使う最低移動量（m）。
  static const double hackerHeadingMinMoveMeters = 8;
}
