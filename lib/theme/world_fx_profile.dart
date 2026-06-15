import '../audio/audio_library.dart';
import '../audio/sfx_id.dart';
import 'world_profile.dart';

/// 決定的瞬間の種類（暴露・捕獲など）。
enum WorldMomentKind {
  namedReveal,
  anonReveal,
  capture,
  accusationUnlock,
  countdown,
}

/// 画面遷移の世界観別スタイル。
enum WorldTransitionStyle {
  cyberSlide,
  horrorFlicker,
  magicalSparkle,
  astronomyZoom,
  tacticalScan,
  sportBounce,
  japaneseShoji,
  westernCurtain,
  defaultFade,
}

/// 名前付き暴露フラッシュの見え方。
enum WorldRevealFlashStyle {
  cyberCyanScan,
  horrorVhs,
  magicalSigil,
  astronomyOrbit,
  tacticalBracket,
  sportPop,
  japaneseGoldMist,
  westernGildedRecord,
}

/// 捕獲フラッシュの見え方。
enum WorldCaptureFlashStyle {
  cyberGlitch,
  horrorHeartbeat,
  magicalImpact,
  astronomyCosmic,
  tacticalMuted,
  sportWhistle,
  japaneseInkImpact,
  westernSealImpact,
}

/// 世界観ごとの音・演出プロファイル（ルール非依存）。
class WorldFxProfile {
  const WorldFxProfile({
    required this.profile,
    required this.uiTapAsset,
    required this.uiBackAsset,
    required this.revealAsset,
    required this.anonRevealAsset,
    required this.captureAsset,
    required this.countdownAsset,
    required this.transitionAsset,
    required this.accusationUnlockAsset,
    this.ambientLoopCandidate,
    required this.transitionStyle,
    required this.revealFlashStyle,
    required this.captureFlashStyle,
    required this.namedRevealBanner,
    required this.anonRevealBanner,
    this.namedRevealFlashMs = 480,
    this.anonRevealFlashMs = 280,
    this.captureFlashMs = 720,
    this.namedRevealFlashOpacity = 0.55,
    this.anonRevealFlashOpacity = 0.30,
    this.captureFlashOpacity = 0.62,
    this.uiTapVolume = 0.60,
    this.revealVolume = 0.78,
    this.transitionVolume = 0.68,
  });

  final WorldProfile profile;

  /// `assets/audio/sfx/worlds/<profile.name>/<asset>.(wav|mp3|…)` のベース名。
  final String uiTapAsset;
  final String uiBackAsset;
  final String revealAsset;
  final String anonRevealAsset;
  final String captureAsset;
  final String countdownAsset;
  final String transitionAsset;
  final String accusationUnlockAsset;

  final AmbientId? ambientLoopCandidate;
  final WorldTransitionStyle transitionStyle;
  final WorldRevealFlashStyle revealFlashStyle;
  final WorldCaptureFlashStyle captureFlashStyle;

  final String namedRevealBanner;
  final String anonRevealBanner;

  final int namedRevealFlashMs;
  final int anonRevealFlashMs;
  final int captureFlashMs;
  final double namedRevealFlashOpacity;
  final double anonRevealFlashOpacity;
  final double captureFlashOpacity;

  /// 世界観別 SE の音量係数（0.0〜1.0）。マスター×効果音に乗算。
  final double uiTapVolume;
  final double revealVolume;
  final double transitionVolume;

  int flashDurationMsFor(WorldMomentKind kind) => switch (kind) {
        WorldMomentKind.namedReveal => namedRevealFlashMs,
        WorldMomentKind.anonReveal => anonRevealFlashMs,
        WorldMomentKind.capture => captureFlashMs,
        WorldMomentKind.accusationUnlock => 420,
        WorldMomentKind.countdown => 360,
      };

  double flashOpacityFor(WorldMomentKind kind) => switch (kind) {
        WorldMomentKind.namedReveal => namedRevealFlashOpacity,
        WorldMomentKind.anonReveal => anonRevealFlashOpacity,
        WorldMomentKind.capture => captureFlashOpacity,
        WorldMomentKind.accusationUnlock => 0.42,
        WorldMomentKind.countdown => 0.38,
      };

  String bannerFor(WorldMomentKind kind) => switch (kind) {
        WorldMomentKind.namedReveal => namedRevealBanner,
        WorldMomentKind.anonReveal => anonRevealBanner,
        WorldMomentKind.capture => '',
        WorldMomentKind.accusationUnlock => '',
        WorldMomentKind.countdown => '',
      };

  /// [SfxId] から世界観別アセットベース名へ。未対応は [SfxId.asset]。
  String assetBaseFor(SfxId id) => switch (id) {
        SfxId.uiTap => uiTapAsset,
        SfxId.uiBack => uiBackAsset,
        SfxId.reveal => revealAsset,
        SfxId.anonReveal => anonRevealAsset,
        SfxId.capture => captureAsset,
        SfxId.uiConfirm => countdownAsset,
        SfxId.matchStart => countdownAsset,
        SfxId.unlock => accusationUnlockAsset,
        _ => id.asset,
      };

  /// 画面遷移用ワンショット。
  String get transitionAssetBase => transitionAsset;
}

/// 8世界観の演出・音マップ。
abstract final class WorldFxCatalog {
  static WorldFxProfile forProfile(WorldProfile profile) =>
      _all[profile] ?? _all[WorldProfile.horror]!;

  static const _all = <WorldProfile, WorldFxProfile>{
    WorldProfile.sciFi: WorldFxProfile(
      profile: WorldProfile.sciFi,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.sonar,
      transitionStyle: WorldTransitionStyle.cyberSlide,
      revealFlashStyle: WorldRevealFlashStyle.cyberCyanScan,
      captureFlashStyle: WorldCaptureFlashStyle.cyberGlitch,
      namedRevealBanner: 'SIGNAL DETECTED',
      anonRevealBanner: 'SCAN PING',
      namedRevealFlashMs: 460,
      anonRevealFlashMs: 260,
      captureFlashMs: 780,
      namedRevealFlashOpacity: 0.52,
      anonRevealFlashOpacity: 0.26,
      captureFlashOpacity: 0.58,
      revealVolume: 0.72,
    ),
    WorldProfile.magical: WorldFxProfile(
      profile: WorldProfile.magical,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.forest,
      transitionStyle: WorldTransitionStyle.magicalSparkle,
      revealFlashStyle: WorldRevealFlashStyle.magicalSigil,
      captureFlashStyle: WorldCaptureFlashStyle.magicalImpact,
      namedRevealBanner: 'VISION REVEALED',
      anonRevealBanner: 'FAIRY TRACE',
      namedRevealFlashMs: 500,
      anonRevealFlashMs: 300,
      captureFlashMs: 820,
      namedRevealFlashOpacity: 0.48,
      anonRevealFlashOpacity: 0.28,
      captureFlashOpacity: 0.55,
      uiTapVolume: 0.55,
    ),
    WorldProfile.horror: WorldFxProfile(
      profile: WorldProfile.horror,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.wind,
      transitionStyle: WorldTransitionStyle.horrorFlicker,
      revealFlashStyle: WorldRevealFlashStyle.horrorVhs,
      captureFlashStyle: WorldCaptureFlashStyle.horrorHeartbeat,
      namedRevealBanner: 'FOUND',
      anonRevealBanner: '…',
      namedRevealFlashMs: 520,
      anonRevealFlashMs: 240,
      captureFlashMs: 860,
      namedRevealFlashOpacity: 0.58,
      anonRevealFlashOpacity: 0.22,
      captureFlashOpacity: 0.65,
      revealVolume: 0.70,
    ),
    WorldProfile.arg: WorldFxProfile(
      profile: WorldProfile.arg,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.comms,
      transitionStyle: WorldTransitionStyle.tacticalScan,
      revealFlashStyle: WorldRevealFlashStyle.tacticalBracket,
      captureFlashStyle: WorldCaptureFlashStyle.tacticalMuted,
      namedRevealBanner: 'TARGET LOGGED',
      anonRevealBanner: 'PING',
      namedRevealFlashMs: 400,
      anonRevealFlashMs: 240,
      captureFlashMs: 700,
      namedRevealFlashOpacity: 0.40,
      anonRevealFlashOpacity: 0.24,
      captureFlashOpacity: 0.50,
    ),
    WorldProfile.astronomy: WorldFxProfile(
      profile: WorldProfile.astronomy,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.beep,
      transitionStyle: WorldTransitionStyle.astronomyZoom,
      revealFlashStyle: WorldRevealFlashStyle.astronomyOrbit,
      captureFlashStyle: WorldCaptureFlashStyle.astronomyCosmic,
      namedRevealBanner: 'OBSERVED',
      anonRevealBanner: 'ECHO',
      namedRevealFlashMs: 440,
      anonRevealFlashMs: 260,
      captureFlashMs: 760,
      namedRevealFlashOpacity: 0.46,
      anonRevealFlashOpacity: 0.26,
      captureFlashOpacity: 0.54,
    ),
    WorldProfile.sport: WorldFxProfile(
      profile: WorldProfile.sport,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.popCity,
      transitionStyle: WorldTransitionStyle.sportBounce,
      revealFlashStyle: WorldRevealFlashStyle.sportPop,
      captureFlashStyle: WorldCaptureFlashStyle.sportWhistle,
      namedRevealBanner: 'SPOTTED!',
      anonRevealBanner: 'blip',
      namedRevealFlashMs: 380,
      anonRevealFlashMs: 220,
      captureFlashMs: 680,
      namedRevealFlashOpacity: 0.44,
      anonRevealFlashOpacity: 0.22,
      captureFlashOpacity: 0.48,
      uiTapVolume: 0.55,
    ),
    WorldProfile.japaneseLuxury: WorldFxProfile(
      profile: WorldProfile.japaneseLuxury,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.forest,
      transitionStyle: WorldTransitionStyle.japaneseShoji,
      revealFlashStyle: WorldRevealFlashStyle.japaneseGoldMist,
      captureFlashStyle: WorldCaptureFlashStyle.japaneseInkImpact,
      namedRevealBanner: '霊気が浮かぶ',
      anonRevealBanner: 'かすかな気配',
      namedRevealFlashMs: 480,
      anonRevealFlashMs: 270,
      captureFlashMs: 740,
      namedRevealFlashOpacity: 0.46,
      anonRevealFlashOpacity: 0.24,
      captureFlashOpacity: 0.52,
      uiTapVolume: 0.55,
      revealVolume: 0.68,
    ),
    WorldProfile.westernLuxury: WorldFxProfile(
      profile: WorldProfile.westernLuxury,
      uiTapAsset: 'ui_tap',
      uiBackAsset: 'ui_back',
      revealAsset: 'reveal',
      anonRevealAsset: 'anon_reveal',
      captureAsset: 'capture',
      countdownAsset: 'countdown',
      transitionAsset: 'transition',
      accusationUnlockAsset: 'accusation_unlock',
      ambientLoopCandidate: AmbientId.wind,
      transitionStyle: WorldTransitionStyle.westernCurtain,
      revealFlashStyle: WorldRevealFlashStyle.westernGildedRecord,
      captureFlashStyle: WorldCaptureFlashStyle.westernSealImpact,
      namedRevealBanner: 'RECORDED',
      anonRevealBanner: 'trace',
      namedRevealFlashMs: 450,
      anonRevealFlashMs: 265,
      captureFlashMs: 720,
      namedRevealFlashOpacity: 0.44,
      anonRevealFlashOpacity: 0.23,
      captureFlashOpacity: 0.50,
      uiTapVolume: 0.58,
      revealVolume: 0.72,
    ),
  };

  /// P0 で外部ファイルを置く想定のパス一覧（存在しなければ合成音へ）。
  static List<String> expectedWorldAssetPaths(WorldProfile profile) {
    final fx = forProfile(profile);
    final id = profile.storageName;
    const exts = ['wav', 'mp3'];
    final bases = [
      fx.uiTapAsset,
      fx.uiBackAsset,
      fx.revealAsset,
      fx.anonRevealAsset,
      fx.captureAsset,
      fx.countdownAsset,
      fx.transitionAsset,
      fx.accusationUnlockAsset,
    ];
    return [
      for (final base in bases)
        for (final ext in exts)
          'assets/audio/sfx/worlds/$id/$base.$ext',
    ];
  }
}
