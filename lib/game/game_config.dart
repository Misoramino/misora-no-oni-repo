class GameConfig {
  /// 標準モデル（45分）。短い検証は [debugMatchDurationSeconds]。
  static const int matchDurationSeconds = 45 * 60;

  static const int debugMatchDurationSeconds = 180;

  /// GPS 至近での即捕獲（拘束中）。BLE 接触は別判定（数 m 級）。
  static const double captureDistanceMeters = 12;
  static const double scaledTouchRadiusMinMeters = 35;
  static const double scaledTouchRadiusMaxMeters = 95;
  static const double scaledTouchRadiusAreaRatio = 0.08;
  static const double scaledRestraintRadiusAreaRatio = 0.10;
  static const double scaledRestraintRadiusMinMeters = 45;
  static const double scaledRestraintRadiusMaxMeters = 110;
  // --- 鬼の接触圏 → 接触拘束（スキル捕獲結界とは別）---
  static const int touchLockRequiredSeconds = 4;
  static const int touchLockRunnerNoticeSeconds = 3;
  /// 拘束持続の下限（[MatchGeoHelpers.touchLockDurationSeconds] が上書き）。
  static const int touchLockDurationMinSeconds = 22;
  static const int touchLockDurationMaxSeconds = 75;
  /// 拘束円を走って抜ける想定速度（持続時間算出用）。
  static const double restraintEscapeRunMps = 2.8;
  static const int touchLockDurationBufferSeconds = 6;
  /// 拘束円外に留まってから脱落まで（秒）。
  static const int bindZoneEscapeGraceSeconds = 10;
  static const double warningDistanceMeters = 120;
  static const double dangerDistanceMeters = 70;

  static const double playAreaRadiusMeters = 500;
  static const int outsideAreaGraceSeconds = 8;
  static const double outsideAreaGraceMeters = 25;
  /// エリア外に留まり続ける場合の追加暴露間隔（秒）。
  static const int outsideAreaRepeatRevealSeconds = 25;
  /// エリア外に留まり続けた場合の脱落（秒）。捕獲結界（約18秒）より長い猶予。
  static const int outsideAreaEliminationSeconds = 90;

  static const double gpsJumpIgnoreMeters = 120;
  /// GPS の異常ジャンプを無視する時間窓（秒）。
  static const int gpsJumpIgnoreWindowSeconds = 2;

  /// 位置 fix がこれより古い場合は捕獲・エリア判定に使わない（秒）。
  static const int gpsMaxFixAgeSeconds = 12;

  /// 復帰直後にローカル判定を抑止する時間（秒）。catch-up 優先。
  static const int resumeCatchUpGraceSeconds = 5;

  /// ホストが background のままこの秒数を超えると他端末に警告表示。
  static const int hostBackgroundWarningSeconds = 90;

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
  /// 逃走者が同じ試合で情報屋を再訪するまで（個人CD・リスク用に長め）。
  static const int infoBrokerCooldownSeconds = 120;
  static const int infoBrokerRespawnSeconds = 45;

  /// ギミック使用後、地点が移動するまでの猶予（この間は旧地点のまま）。
  static const int gimmickRelocateDelaySeconds = 12;

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
  /// 同一カメラの再検知まで（通過のたびに匿名痕跡・通知が出る）。
  static const int cameraRetriggerCooldownSeconds = 90;
  static const int cameraMinCount = 4;
  static const int cameraMaxCount = 16;
  static const int fakeSkillCooldownSeconds = 72;
  static const int fakeSkillDurationSeconds = 20;
  /// 偽位置の初期スポーン: 現在地から進行方向へこの距離（m）。
  static const double fakePositionSpawnOffsetMeters = 38;
  /// 偽位置が進行方向へ流れる速さ（m/s）。
  static const double fakePositionDriftSpeedMps = 3.4;
  static const int fakeIntelRevealCooldownSeconds = 75;
  static const int fakeIntelMapTapWindowSeconds = 25;

  /// 人狼の任意鬼化CDは [WerewolfForcedSchedule.voluntaryTransformCooldownSeconds] を参照。
  // --- スキル「捕獲結界」（逃走者・鬼共通・地図配置）---
  static const double captureZoneSkillRadiusMeters = 55;
  /// 互換エイリアス（スキル結界の半径）。
  static const double captureZoneRadiusMeters = captureZoneSkillRadiusMeters;
  static const int captureZoneDurationSeconds = 24;
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

  // --- 感染（接触圏より外側の環；エリア連動）---
  static const double scaledInfectionRadiusAreaRatio = 0.14;
  static const double infectionTriggerMinMeters = 58;
  static const double infectionTriggerMaxMeters = 115;
  static const int infectionExposureSeconds = 6;
  static const int infectionDurationSeconds = 22;
  static const int infectionRevealIntervalSeconds = 7;

  // Accusation (告発)
  static const int accusationMinPlayers = 3;
  static const double accusationUnlockTimeRatio = 0.6;
  static const int accusationUnlockMinElapsedSeconds = 300;
  static const double accusationFacilityRadiusMeters = 35;
  /// 生存鬼がこの半径内にいると、その告発施設での告発を不可にする。
  static const double accusationHunterBlockRadiusMeters = accusationFacilityRadiusMeters;

  /// 鬼軌跡の遅延帯は [MatchDurationScaling.oniTrail] を使用（試合時間連動）。
  @Deprecated('Use MatchDurationScaling.oniTrail')
  static const int oniTrailMinDisplayAgeSeconds = 600;
  @Deprecated('Use MatchDurationScaling.oniTrail')
  static const int oniTrailMaxDisplayAgeSeconds = 780;
  @Deprecated('Use MatchDurationScaling.oniTrail')
  static const int oniTrailRetainSeconds = 900;
  static const int accusationFacilityMinCount = 3;
  static const int accusationFacilityMaxCount = 5;

  // Camera jack (残響体)
  static const int cameraJackChargeSeconds = 15;
  static const int cameraJackPersonalCooldownSeconds = 100;
  static const int cameraJackMatchLimit = 5;
  static const double cameraJackSiteRadiusMeters = 28;

  // 復讐の鬼影 — 告発施設妨害
  static const int facilitySabotageChargeSeconds = 18;
  static const int facilitySabotagePersonalCooldownSeconds = 90;
  /// 告発施設の妨害・無効化（合計回数）。
  static const int facilitySabotageMatchLimit = 3;

  // 復讐の鬼影 — カメラシャットダウン（各カメラ1回・回数上限なし）
  static const int cameraShutdownChargeSeconds = 14;
  static const int cameraShutdownPersonalCooldownSeconds = 25;

  // 残響体 — 告発施設陣取り（有効数 +1）
  static const int spectralTerritoryChargeSeconds = 16;
  static const int spectralTerritoryPersonalCooldownSeconds = 90;
  static const int spectralTerritoryMatchLimit = 2;

  /// ハッカー: 鬼の向き表示に使う最低移動量（m）。
  static const double hackerHeadingMinMoveMeters = 8;

  /// ハートビート途絶・切断とみなす時間（秒）。ホスト譲渡・切断脱落で共通。
  static const int memberPresenceStaleSeconds = 120;

  /// 切断判定（[memberPresenceStaleSeconds] 超過）後、脱落までの猶予（秒）。
  /// ホスト tick 間の揺れ用。合計 ≒2分で脱落。
  static const int disconnectEliminationGraceSeconds = 15;

  /// 試合中バックグラウンド（他アプリ・画面ロック）の最大猶予（秒）。
  /// この間はハートビート停止でも切断脱落しない。
  static const int matchBackgroundMaxSeconds = 15 * 60;

  /// ホスト開始後、この秒数以内の同期参加はカウントダウン＋役職案内を表示。
  static const int syncJoinFullPresentationMaxSeconds = 45;

  /// この秒数以内なら再参加通知のあと役職案内を必ず表示。
  static const int syncJoinRoleBriefingMaxSeconds = 90;
}
