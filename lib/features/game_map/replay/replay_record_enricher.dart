import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_state.dart';
import '../../../game/match_event.dart';
import '../../../game/match_record.dart';
import '../../../game/play_area.dart';
import '../../../sync/firestore_room_blueprint.dart';

/// リプレイ直前に記録を補完（旧記録の endReason からイベント復元など）。
abstract final class ReplayRecordEnricher {
  static SavedMatchRecord prepare(SavedMatchRecord raw) {
    final events = List<MatchEvent>.from(raw.events);

    if (!events.any((e) => e.type == 'accusation_success') &&
        raw.endReason == MatchEndReason.accusationSuccess) {
      final anchor = _lastAccusationPosition(events, raw);
      final at = raw.endedAtUtc.subtract(const Duration(milliseconds: 800));
      events.add(
        MatchEvent(
          type: 'accusation_success',
          atUtc: at,
          message: '告発成功',
          position: anchor,
        ),
      );
    }

    if (!events.any((e) => e.type == 'match_end')) {
      events.add(
        MatchEvent(
          type: 'match_end',
          atUtc: raw.endedAtUtc,
          message: _matchEndMessage(raw),
          position: _endPosition(raw),
        ),
      );
    }

    events.sort((a, b) => a.atUtc.compareTo(b.atUtc));
    return SavedMatchRecord(
      version: raw.version,
      id: raw.id,
      startedAtUtc: raw.startedAtUtc,
      endedAtUtc: raw.endedAtUtc,
      outcome: raw.outcome,
      consentedToTrajectory: raw.consentedToTrajectory,
      playArea: raw.playArea,
      tracks: raw.tracks,
      trackLabels: raw.trackLabels,
      trackKinds: raw.trackKinds,
      reveals: raw.reveals,
      events: events,
      endReason: raw.endReason,
      winningFaction: raw.winningFaction,
      gimmickLayout: raw.gimmickLayout,
      worldProfile: raw.worldProfile,
      onlineRoomId: raw.onlineRoomId,
      onlineSessionKey: raw.onlineSessionKey,
    );
  }

  static LatLng _lastAccusationPosition(
    List<MatchEvent> events,
    SavedMatchRecord raw,
  ) {
    for (final e in events.reversed) {
      if (e.type.contains('accusation')) return e.position;
    }
    return raw.playArea.centerOrFirstPoint;
  }

  static LatLng _endPosition(SavedMatchRecord raw) {
    for (final samples in raw.tracks.values) {
      if (samples.isNotEmpty) return samples.last.position;
    }
    return raw.playArea.centerOrFirstPoint;
  }

  static String _matchEndMessage(SavedMatchRecord raw) {
    return switch (raw.endReason) {
      MatchEndReason.accusationSuccess => '告発成功で試合終了',
      MatchEndReason.timeUp => '時間切れ',
      MatchEndReason.allHumansEliminated => '全員脱落',
      MatchEndReason.oniEliminated => '鬼撃破',
      MatchEndReason.caught => '捕獲',
      MatchEndReason.hostAbort => '試合中止',
      MatchEndReason.hostEnded => 'ホスト終了',
      _ => switch (raw.outcome) {
          GameState.runnerWin => '逃走側の勝利',
          GameState.caughtByOni => '鬼の勝利',
          _ => '試合終了',
        },
    };
  }
}

extension _PlayAreaCenter on PlayArea {
  LatLng get centerOrFirstPoint {
    switch (type) {
      case PlayAreaType.circle:
        return center;
      case PlayAreaType.polygon:
        return points.isEmpty ? const LatLng(0, 0) : points.first;
    }
  }
}
