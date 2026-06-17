import '../../../game/elimination_aftermath_rule.dart';
import '../../../features/how_to_play/guide_terms.dart';
import '../../../services/match_recorder.dart';

/// リプレイ軌跡の表示種別（ゲームロジック非依存）。
enum ReplayTrackKind {
  survivor,
  secondGame,
  spectral,
  revengeOni,
  ghostSpectator,
  oni,
  spectator,
}

/// 軌跡 ID と脱落後ルールの対応。
abstract final class ReplayTrackStyle {
  static String trackIdForRule(EliminationAftermathRule rule) =>
      switch (rule) {
        EliminationAftermathRule.spectralOperative =>
          MatchTrackIds.spectralLocal,
        EliminationAftermathRule.revenantOni => MatchTrackIds.revengeOniLocal,
        EliminationAftermathRule.joinOni => MatchTrackIds.revengeOniLocal,
        EliminationAftermathRule.ghostSpectator =>
          MatchTrackIds.ghostSpectatorLocal,
      };

  static ReplayTrackKind kindForRule(EliminationAftermathRule rule) =>
      switch (rule) {
        EliminationAftermathRule.spectralOperative => ReplayTrackKind.spectral,
        EliminationAftermathRule.revenantOni => ReplayTrackKind.revengeOni,
        EliminationAftermathRule.joinOni => ReplayTrackKind.revengeOni,
        EliminationAftermathRule.ghostSpectator =>
          ReplayTrackKind.ghostSpectator,
      };

  static ReplayTrackKind kindForTrackId(
    String id, {
    Map<String, String>? trackKinds,
  }) {
    final named = trackKinds?[id];
    if (named != null) {
      for (final k in ReplayTrackKind.values) {
        if (k.name == named) return k;
      }
    }
    if (id == MatchTrackIds.oniLocal || id.contains('_oni_')) {
      return ReplayTrackKind.oni;
    }
    if (id == MatchTrackIds.spectralLocal || id.contains('spectral')) {
      return ReplayTrackKind.spectral;
    }
    if (id == MatchTrackIds.revengeOniLocal || id.contains('revenge')) {
      return ReplayTrackKind.revengeOni;
    }
    if (id == MatchTrackIds.ghostSpectatorLocal || id.contains('ghost')) {
      return ReplayTrackKind.ghostSpectator;
    }
    if (id == MatchTrackIds.secondGameLocal || id.contains('second_game')) {
      return ReplayTrackKind.secondGame;
    }
    if (id.startsWith('player_')) return ReplayTrackKind.survivor;
    if (id == MatchTrackIds.runnerLocal) return ReplayTrackKind.survivor;
    return ReplayTrackKind.survivor;
  }

  /// 生存中 solid / 脱落後は薄く点線寄り。
  static bool useDashedLine(ReplayTrackKind kind) => switch (kind) {
        ReplayTrackKind.survivor || ReplayTrackKind.oni => false,
        _ => true,
      };

  static double lineOpacity(ReplayTrackKind kind, {required bool emphasized}) {
    final base = switch (kind) {
      ReplayTrackKind.survivor => 0.92,
      ReplayTrackKind.oni => 0.9,
      ReplayTrackKind.spectral => 0.55,
      ReplayTrackKind.revengeOni => 0.5,
      ReplayTrackKind.secondGame => 0.48,
      ReplayTrackKind.ghostSpectator => 0.42,
      ReplayTrackKind.spectator => 0.4,
    };
    if (emphasized) return (base + 0.12).clamp(0.0, 1.0);
    return base;
  }

  static double dimmedOpacity(ReplayTrackKind kind, {required bool emphasized}) {
    if (emphasized) return lineOpacity(kind, emphasized: true);
    return (lineOpacity(kind, emphasized: false) * 0.55).clamp(0.12, 0.75);
  }

  /// リプレイの軌跡チップ・凡例向けの既定ラベル。
  static String defaultTrackLabel(
    String id, {
    Map<String, String>? trackLabels,
    Map<String, String>? trackKinds,
  }) {
    final custom = trackLabels?[id];
    if (custom != null && custom.isNotEmpty) return custom;
    final kind = kindForTrackId(id, trackKinds: trackKinds);
    return switch (kind) {
      ReplayTrackKind.oni => GuideTerms.trueOni,
      ReplayTrackKind.spectral => '残響体',
      ReplayTrackKind.revengeOni => '復讐の鬼影',
      ReplayTrackKind.ghostSpectator => '幽霊（観戦）',
      ReplayTrackKind.secondGame => '第二ゲーム',
      ReplayTrackKind.spectator => '観戦',
      ReplayTrackKind.survivor =>
        id == MatchTrackIds.runnerLocal ? '自分' : _playerIdLabel(id),
    };
  }

  static String defaultTrackTitle(
    String id, {
    Map<String, String>? trackLabels,
    Map<String, String>? trackKinds,
  }) {
    final custom = trackLabels?[id];
    if (custom != null && custom.isNotEmpty) return custom;
    final kind = kindForTrackId(id, trackKinds: trackKinds);
    return switch (kind) {
      ReplayTrackKind.oni => '${GuideTerms.trueOni}（再生）',
      ReplayTrackKind.survivor =>
        id == MatchTrackIds.runnerLocal ? '自分（再生）' : '${_playerIdLabel(id)}（再生）',
      _ => defaultTrackLabel(
          id,
          trackLabels: trackLabels,
          trackKinds: trackKinds,
        ),
    };
  }

  static String _playerIdLabel(String id) {
    if (id.startsWith('player_')) return id.substring(7);
    return id;
  }
}
