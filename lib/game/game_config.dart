class GameConfig {
  static const int matchDurationSeconds = 180;

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

  static const int werewolfTransformDurationSeconds = 20;
  static const int werewolfTransformCooldownSeconds = 90;
  static const double captureZoneRadiusMeters = 55;
  static const int captureZoneDurationSeconds = 16;
  static const int captureZoneCooldownSeconds = 80;
  static const double bodyThrowDistanceMeters = 90;
  static const int bodyThrowDurationSeconds = 12;
  static const int bodyThrowCooldownSeconds = 75;

  // Phase 2.5: infection and trace
  static const double infectionTriggerDistanceMeters = 38;
  static const int infectionExposureSeconds = 6;
  static const int infectionDurationSeconds = 22;
  static const int infectionRevealIntervalSeconds = 7;
}
