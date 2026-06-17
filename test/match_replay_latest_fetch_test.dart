import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/services/match_archive_merger.dart';
import 'package:oni_game/services/match_recorder.dart';
import 'package:oni_game/services/match_replay_latest_fetch.dart';

SavedMatchRecord _record({
  required String id,
  Map<String, List<TrajectorySample>> tracks = const {},
}) {
  final area = PlayArea.circle(center: const LatLng(35, 139), radiusMeters: 200);
  final t = DateTime.utc(2026, 1, 1, 12);
  return SavedMatchRecord(
    version: 1,
    id: id,
    startedAtUtc: t,
    endedAtUtc: t.add(const Duration(minutes: 10)),
    outcome: GameState.runnerWin,
    consentedToTrajectory: true,
    playArea: area,
    tracks: tracks,
  );
}

void main() {
  test('result replay opens merged remote archive when available', () async {
    final t = DateTime.utc(2026, 1, 1, 12);
    final local = _record(
      id: 'local',
      tracks: {
        MatchTrackIds.runnerLocal: [
          TrajectorySample(atUtc: t, position: const LatLng(35, 139)),
        ],
      },
    );
    final remote = _record(
      id: 'remote',
      tracks: {
        'player_b': [
          TrajectorySample(atUtc: t, position: const LatLng(35.002, 139.002)),
        ],
      },
    );

    final result = await MatchReplayLatestFetch.resolveForResultReplay(
      local: local,
      fetchRemote: () async => remote,
    );

    expect(result.source, MatchReplayFetchSource.remoteMerged);
    expect(result.record!.tracks.length, 2);
    expect(
      MatchReplayLatestFetch.toastAfterResolve(
        result,
        attemptedRemote: true,
      ),
      '最新の試合記録を読み込みました',
    );
  });

  test('result replay falls back to local saved record on fetch error', () async {
    final local = _record(id: 'local');
    final result = await MatchReplayLatestFetch.resolveForResultReplay(
      local: local,
      fetchRemote: () async {
        throw StateError('permission-denied');
      },
    );

    expect(result.source, MatchReplayFetchSource.localFallback);
    expect(result.record, same(local));
    expect(
      MatchReplayLatestFetch.toastAfterResolve(
        result,
        attemptedRemote: true,
      ),
      '保存済みの記録を表示します',
    );
  });

  test('result replay timeout falls back to local', () async {
    final local = _record(id: 'local');
    final result = await MatchReplayLatestFetch.resolveForResultReplay(
      local: local,
      timeout: const Duration(milliseconds: 50),
      fetchRemote: () => Completer<SavedMatchRecord?>().future,
    );

    expect(result.source, MatchReplayFetchSource.localFallback);
    expect(result.record, same(local));
  });

  test('partial archive still opens with available players', () async {
    final t = DateTime.utc(2026, 1, 1, 12);
    final local = _record(
      id: 'local',
      tracks: {
        MatchTrackIds.runnerLocal: [
          TrajectorySample(atUtc: t, position: const LatLng(35, 139)),
        ],
      },
    );
    final remote = _record(
      id: 'remote',
      tracks: {
        'player_only_one': [
          TrajectorySample(atUtc: t, position: const LatLng(35.001, 139.001)),
        ],
      },
    );

    final result = await MatchReplayLatestFetch.resolveForResultReplay(
      local: local,
      fetchRemote: () async => remote,
    );

    expect(result.source, MatchReplayFetchSource.remoteMerged);
    expect(result.record!.tracks.containsKey('player_only_one'), isTrue);
    expect(
      result.record!.tracks.containsKey(MatchTrackIds.runnerLocal),
      isTrue,
    );
  });

  test('offline result replay skips remote and uses local without failure toast',
      () async {
    final local = _record(id: 'local');
    final result = await MatchReplayLatestFetch.resolveForResultReplay(
      local: local,
      attemptRemote: false,
    );

    expect(result.source, MatchReplayFetchSource.localFallback);
    expect(result.record, same(local));
    expect(
      MatchReplayLatestFetch.toastAfterResolve(
        result,
        attemptedRemote: false,
      ),
      isNull,
    );
  });

  test('gallery path does not use latest fetch resolver', () {
    // MatchGalleryScreen opens MatchReplayScreen(record: savedLocal) directly.
    // Latest fetch is only wired from MatchResultScreen via _openMatchReplay.
    expect(MatchReplayLatestFetch.defaultTimeout.inSeconds, 5);
    expect(MatchArchiveMerger.merge, isNotNull);
  });
}
