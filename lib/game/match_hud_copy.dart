import '../features/how_to_play/guide_terms.dart';
import 'match_ui_terms.dart';

/// 試合中 HUD・通知・イベントログのプレイヤー向け文言。
abstract final class MatchHudCopy {
  // --- パニック ---
  static const panicExposureStart = '鬼が近くにいます';
  static const panicExposureStartDetail = '離れましょう';
  static const panicExposureImminent = 'あと少しでパニックです';
  static const panicExposureImminentDetail = 'このままだとパニックになります';
  static const panicStartedEvent = 'パニック発生';
  static const panicStartedStatus = '落ち着かない状態です。離れると落ち着きます';
  static const panicTraceSnack =
      '${GuideTerms.anonPositionReveal}され、${GuideTerms.anonTrace}が残りました';
  static String panicActiveCountdown(int secondsLeft) =>
      '落ち着くまであと$secondsLeft秒';
  static String panicDangerCountdown(int secondsLeft) =>
      'あと約$secondsLeft秒でパニック';

  // --- 接触・拘束・捕獲 ---
  static const contactRingEntered = '鬼に近すぎます';
  static const contactRingEnteredDetail = 'このままだと拘束されます';
  static const contactRingCountdownPrefix = '拘束まで あと';
  static const contactRingCountdownSuffix = '秒';
  static const restraintStarted = '拘束されました';
  static const restraintStartedDetail = '大きな円の外に出れば助かります';
  static const restraintLockStatusPrefix = '拘束中: 残り';
  static const restraintLockStatusSuffix = '秒 — ごく至近で捕獲の恐れ';
  static const captureSucceeded = '捕獲されました';
  static const captureSucceededDetail = '${GuideTerms.secondGame}に移行します。';
  static const captureSucceededOni = '捕獲成功';
  static const captureSucceededOniDetail = '人側生存者を追い詰めました。';
  static const captureZoneEscapeReveal = '捕獲結界から離脱 — ${MatchUiTerms.namedReveal}';
  static const touchRestraintEscapeReveal = '止められ圏から離脱 — ${MatchUiTerms.namedReveal}';
  static const captureZoneLongEscape = '捕獲結界から長時間離脱しました。';
  static const touchRestraintLongEscape = '止められ圏から長時間離脱しました。';

  static String touchLockEvent({
    required double touchRadiusMeters,
    required double restraintRadiusMeters,
    required int bindDurationSeconds,
  }) =>
      '近づき圏 ${touchRadiusMeters.toStringAsFixed(0)}m → 止められ圏 '
      '${restraintRadiusMeters.toStringAsFixed(0)}m（$bindDurationSeconds秒）';

  // --- 名前付き暴露・不明な痕跡 ---
  static String namedRevealStatus(String playerLabel, String reason) =>
      reason.isEmpty
          ? '$playerLabel の${MatchUiTerms.namedReveal}'
          : '$playerLabel がここで${MatchUiTerms.namedReveal}されました（$reason）';

  static String namedRevealAlert(String playerLabel, String reason) =>
      reason.isEmpty
          ? '$playerLabel がこの付近で${MatchUiTerms.namedReveal}されました'
          : '$playerLabel がこの付近で${MatchUiTerms.namedReveal}されました（$reason）';

  static const anonRevealAction = '${GuideTerms.anonPositionReveal}が行われた';
  static const anonTraceFallback = '${GuideTerms.anonTrace}が出ました';
  static const revealLogTitle = '暴露ログ';
  static const namedRevealLogTitle = MatchUiTerms.namedReveal;
  static const intelAndRevealTitle = '鬼情報・暴露';

  // --- エリア外 ---
  static const outsideAreaWarning = 'エリア外です';
  static const outsideAreaWarningDetail = 'エリア外は危険です';
  static const outsideAreaCountdownPrefix = 'エリア外 — あと';
  static const outsideAreaCountdownSuffix = '秒で脱落';
  static const outsideAreaFarFromBorder = 'エリア外（境界から離れすぎ）';
  static const outsideAreaBorderHint = 'エリア外 — 境界から離れています';
  static const safeChargeConsumed = '安全地帯チャージを消費';
  static const safeChargeConsumedDetail = 'エリア外暴露を防ぎました。';
  static const outsideEliminationSuffix = 'エリア外が続いたため脱落';

  // --- 告発 ---
  static const accusationUnlocked = '告発施設が解禁されました';
  static const accusationUnlockedDetail = '${GuideTerms.trueOni}を当てれば勝てます';
  static const accusationFacilityBlocked = 'この施設では告発できません';
  static const accusationFacilityBlockedDetail =
      '${GuideTerms.trueOni}が施設の近くにいます';
  static const accusationWerewolfDisabled = '人狼は告発できません';
  static const accusationSuccess = '告発成功';
  static const accusationSuccessDetail = '${GuideTerms.trueOni}を当てました';
  static const accusationSuccessHumanWin = '${GuideTerms.humanFaction}の勝利です。';
  static const accusationFailed = '告発失敗';
  static const accusationFailedDetail = '${GuideTerms.trueOni}ではありませんでした';
  static const accusationFailedEliminated = '告発者は脱落します。';
  static const accusationSpent = 'この試合では告発済みです';

  static String accusationUnlockFeed(String facilityName) =>
      '告発解禁 — $facilityName';

  // --- 勝敗・試合中止 ---
  static const humanFactionWin = '${GuideTerms.humanFaction}の勝利';
  static const oniFactionWin = '${GuideTerms.oniFaction}の勝利';
  static const humanWinTimeUpDetail = '制限時間まで生存者が残りました。';
  static const humanWinAccusationDetail = '${GuideTerms.trueOni}を告発しました。';
  static const humanWinOniEliminatedDetail = '${GuideTerms.trueOni}が全員いなくなりました。';
  static const oniWinDetail = '人側生存者が0人になりました。';
  static const matchAborted = '試合中止';
  static const matchAbortedDetail = '勝敗・戦績は記録されません。';
  static const matchAbortedMajority = '過半数の賛成で試合を中止しました';

  static String matchEndTimeUp() => '$humanFactionWin — $humanWinTimeUpDetail';

  static String matchEndAllHumansEliminated() =>
      '$oniFactionWin — $oniWinDetail';

  static String matchEndOniEliminated() =>
      '$humanFactionWin — $humanWinOniEliminatedDetail';

  static String matchEndAccusationSuccess() =>
      '$humanFactionWin — $humanWinAccusationDetail';

  // --- 第二ゲーム ---
  static const secondGameTransition = '${GuideTerms.secondGame}に移行します。';
  static const eliminatedByDisconnect =
      '通信が途絶えたため脱落 — ${GuideTerms.secondGame}へ';
  static const eliminatedFeed = '誰かが脱落しました';
  static const accusationFailedFeed = '告発失敗 — 告発者が脱落';

  static String eliminationCaptured(String roleTitle, String roleSubtitle) =>
      '捕獲 — $roleTitleとして戦線に残ります。$roleSubtitle';

  static String eliminationSpectator(String roleTitle) =>
      '脱落 — $roleTitleとして観戦します。試合終了までお待ちください。';

  static String eliminationJoinOni(String roleTitle) =>
      '脱落 — $roleTitleとして鬼側の索敵を支援します。';

  static const spectralTerritoryCharging = '告発施設を陣取り中';
  static const spectralTerritorySuccess = '告発施設を確保';
  static const spectralTerritorySuccessDetail = '有効な告発施設が増えました。';
  static const spectralTerritoryFeed = '残響体が告発施設を陣取った';
  static const facilitySabotageCharging = '告発施設を妨害中';
  static const facilitySabotageSuccess = '告発施設を妨害';
  static const facilitySabotageSuccessDetail = '有効な告発施設が減りました。';
  static const facilitySabotageFeed = '復讐の鬼影が告発施設を妨害した';

  // --- スキル ---
  static const fakePositionEnded = '偽位置終了';
  static const fakePositionEndedEvent = '偽位置スキルが終了';
  static const captureZonePlaced = '捕獲結界を設置';
  static const captureZonePlacedStatus = '捕獲結界を設置しました';
  static const disruptionZonePlaced =
      '攪乱結界を設置（拘束のみ・捕獲不可）';
  static const captureZoneEnded = '捕獲結界が終了';
  static const touchRestraintReleased = '拘束が解除されました';
  static const bodyThrowMissReveal =
      '体投げ未回収 — ${MatchUiTerms.namedReveal}（人形の位置）';

  // --- 施設・その他 ---
  static const safeZoneRespawned = '安全地帯が再出現しました';
  static const infoBrokerRespawned = '情報屋が再出現しました';
  static const cameraSpottedPrefix = '監視カメラ: 誰かが監視地点';
  static const cameraSpottedSuffix = '付近を通過';

  static String cameraSpottedMessage(int siteIndex) =>
      '$cameraSpottedPrefix${siteIndex + 1}$cameraSpottedSuffix';

  // --- リザルト個人 ---
  static const resultCapturedTitle = '捕獲されました';
  static String resultAfterCatchSubtitle(String roleLine) =>
      '$roleLine。$secondGameTransition';
}
