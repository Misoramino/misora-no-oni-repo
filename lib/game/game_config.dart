class GameConfig {
  static const int matchDurationSeconds = 180;

  static const double captureDistanceMeters = 35;
  static const double warningDistanceMeters = 120;
  static const double dangerDistanceMeters = 70;

  static const double playAreaRadiusMeters = 500;
  static const int outsideAreaGraceSeconds = 8;
  static const double outsideAreaGraceMeters = 25;

  static const double gpsJumpIgnoreMeters = 120;
  static const int gpsJumpIgnoreWindowSeconds = 2;

  // Phase 2 prep: map gimmicks
  static const double safeZoneRadiusMeters = 40;
  static const int safeZoneMaxCharges = 2;
  static const int safeZoneChargeCooldownSeconds = 25;
  static const int safeZoneRespawnSeconds = 40;

  static const double infoBrokerRadiusMeters = 30;
  static const int infoBrokerCooldownSeconds = 35;
  static const int infoBrokerRespawnSeconds = 45;

  static const int periodicRevealIntervalSeconds = 40;

  // Phase 2: info-war tuning
  static const double commJammingZoneRadiusMeters = 75;
  static const int commJammingCycleSeconds = 18;
  static const double cameraTriggerRadiusMeters = 28;
  static const int fakeSkillCooldownSeconds = 45;
  static const int fakeSkillDurationSeconds = 14;
}
