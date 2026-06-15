import '../audio/sfx_id.dart';
import '../theme/world_fx_profile.dart';
import '../theme/world_profile.dart';

/// 設定画面などから試聴する世界観 SE の種類。
enum WorldSfxPreviewKind {
  uiTap,
  reveal,
  transition,
}

extension WorldSfxPreviewKindLabels on WorldSfxPreviewKind {
  String get buttonLabel => switch (this) {
        WorldSfxPreviewKind.uiTap => 'UI音',
        WorldSfxPreviewKind.reveal => '暴露音',
        WorldSfxPreviewKind.transition => '遷移音',
      };

  /// [GameAudio.playSfx] に渡す ID。遷移音は [GameAudio.playTransitionSfx] を使う。
  SfxId? get sfxId => switch (this) {
        WorldSfxPreviewKind.uiTap => SfxId.uiTap,
        WorldSfxPreviewKind.reveal => SfxId.reveal,
        WorldSfxPreviewKind.transition => null,
      };

  /// 同じ音が短時間に重ならないよう抑える間隔（ミリ秒）。
  int get debounceMs => switch (this) {
        WorldSfxPreviewKind.uiTap => 100,
        WorldSfxPreviewKind.reveal => 500,
        WorldSfxPreviewKind.transition => 250,
      };

  double volumeCoeff(WorldFxProfile fx) => switch (this) {
        WorldSfxPreviewKind.uiTap => fx.uiTapVolume,
        WorldSfxPreviewKind.reveal => fx.revealVolume,
        WorldSfxPreviewKind.transition => fx.transitionVolume,
      };
}

/// 世界観 SE 試聴の SfxId / profile 対応（テスト用にも利用）。
abstract final class WorldSfxPreview {
  static SfxId? sfxIdFor(WorldSfxPreviewKind kind) => kind.sfxId;

  static double volumeFor(WorldProfile profile, WorldSfxPreviewKind kind) {
    final fx = WorldFxCatalog.forProfile(profile);
    return kind.volumeCoeff(fx);
  }
}
