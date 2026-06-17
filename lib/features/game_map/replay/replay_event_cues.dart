import '../../../audio/sfx_id.dart';
import '../../../game/location_reveal_event.dart';
import '../../../game/match_event.dart';
import 'replay_director.dart';

/// リプレイ中のイベント同期（SE・フラッシュ・マーカー強調）。
abstract final class ReplayEventCues {
  static ReplayCinematicCue fromMatchEvent(MatchEvent e) {
    final type = e.type;
    final revealLike = type.contains('reveal');
    final captureLike =
        type.contains('capture') && !type.contains('capture_zone_ack');
    final accusationFlash = type.contains('accusation_success') ||
        type.contains('accusation_attempt');
    return ReplayCinematicCue(
      atUtc: e.atUtc,
      position: e.position,
      kind: type,
      flashReveal: revealLike || captureLike || accusationFlash,
      flashStrong: type.contains('accusation_success') || type == 'match_end',
      playSfx: !type.contains('capture_zone_ack'),
      fadeMuted: type.contains('accusation_failed'),
    );
  }

  static ReplayCinematicCue fromReveal(LocationRevealEvent r) {
    return ReplayCinematicCue(
      atUtc: r.timestamp,
      position: r.position,
      kind: 'location_reveal',
      flashReveal: true,
      flashStrong: false,
      playSfx: true,
      fadeMuted: false,
    );
  }

  static SfxId? sfxForCue(
    ReplayCinematicCue cue, {
    String? endReason,
    String? outcomeName,
  }) {
    final k = cue.kind;
    if (k == 'match_end' || k.contains('match_end')) {
      if (endReason == 'accusation_success' || outcomeName == 'runnerWin') {
        return SfxId.matchWin;
      }
      if (outcomeName == 'caughtByOni') return SfxId.matchLose;
      return SfxId.uiConfirm;
    }
    if (k.contains('accusation_success')) return SfxId.matchWin;
    if (k.contains('accusation_failed')) return SfxId.denied;
    if (k.contains('accusation_point_scored')) return SfxId.reward;
    if (k.contains('accusation_attempt')) return SfxId.uiConfirm;
    if (k.contains('safe_zone_pickup')) return SfxId.reward;
    if (k.contains('capture_zone_bound') || k == 'capture') {
      return SfxId.capture;
    }
    if (k.contains('fake_intel') || k.contains('anonymous')) {
      return SfxId.anonReveal;
    }
    if (k.contains('reveal')) return SfxId.reveal;
    if (k.contains('accusation_unlocked')) return SfxId.unlock;
    if (k.contains('player_eliminated')) return SfxId.capture;
    if (k.contains('capture_zone_placed') ||
        k.contains('capture_zone_start')) {
      return SfxId.skillCast;
    }
    return null;
  }

  static String cueKey(ReplayCinematicCue cue) =>
      '${cue.kind}|${cue.atUtc.microsecondsSinceEpoch}|'
      '${cue.position.latitude}|${cue.position.longitude}';
}
