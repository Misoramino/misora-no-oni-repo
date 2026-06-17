import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/audio/sfx_id.dart';
import 'package:oni_game/features/game_map/replay/replay_capture_zone.dart';
import 'package:oni_game/features/game_map/replay/replay_record_enricher.dart';
import 'package:oni_game/features/game_map/replay/replay_sfx_gate.dart';
import 'package:oni_game/features/game_map/replay/replay_track_kind.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/match_event.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/services/match_archive_merger.dart';
import 'package:oni_game/services/match_recorder.dart';
import 'package:oni_game/services/match_replay_latest_fetch.dart';
import 'package:oni_game/theme/world_profile.dart';

SavedMatchRecord _sampleRecord({
  List<MatchEvent>? events,
  String? endReason,
  String? worldProfile,
  Map<String, String>? trackKinds,
  Map<String, List<TrajectorySample>>? tracks,
}) {
  final t0 = DateTime.utc(2026, 6, 1, 12);
  return SavedMatchRecord(
    version: 2,
    id: 'test',
    startedAtUtc: t0,
    endedAtUtc: t0.add(const Duration(minutes: 10)),
    outcome: GameState.runnerWin,
    consentedToTrajectory: true,
    playArea: PlayArea.circle(center: const LatLng(35, 139), radiusMeters: 200),
    tracks: tracks ??
        {
          MatchTrackIds.runnerLocal: [
            TrajectorySample(atUtc: t0, position: const LatLng(35, 139)),
            TrajectorySample(
              atUtc: t0.add(const Duration(minutes: 5)),
              position: const LatLng(35.001, 139.001),
            ),
          ],
        },
    trackKinds: trackKinds ?? const {},
    events: events ?? const [],
    endReason: endReason,
    worldProfile: worldProfile,
    onlineRoomId: 'room1',
    onlineSessionKey: 42,
  );
}

void main() {
  test('replay SE gate throttles at high speed', () {
    final gate = ReplaySfxGate(
      clock: () => DateTime.utc(2026, 1, 1, 12, 0, 0),
    );
    expect(
      gate.tryAcquire(
        cueKind: 'reveal',
        replaySpeed: 4,
        sfx: SfxId.reveal,
      ),
      isTrue,
    );
    expect(
      gate.tryAcquire(
        cueKind: 'reveal',
        replaySpeed: 4,
        sfx: SfxId.reveal,
      ),
      isFalse,
    );
    expect(
      gate.tryAcquire(
        cueKind: 'accusation_success',
        replaySpeed: 16,
        sfx: SfxId.matchWin,
      ),
      isTrue,
    );
    expect(
      gate.tryAcquire(
        cueKind: 'reveal',
        replaySpeed: 16,
        sfx: SfxId.reveal,
      ),
      isFalse,
    );
  });

  test('match_end cue enriched once', () {
    final raw = _sampleRecord(endReason: 'accusation_success');
    final prepared = ReplayRecordEnricher.prepare(raw);
    expect(
      prepared.events.where((e) => e.type == 'match_end').length,
      1,
    );
    expect(
      prepared.events.any((e) => e.type == 'accusation_success'),
      isTrue,
    );
  });

  test('capture zone placed ack bound lifecycle', () {
    final t0 = DateTime.utc(2026, 6, 1, 12);
    final events = [
      MatchEvent(
        type: 'capture_zone_placed',
        atUtc: t0,
        message: '設置 place:zoneA',
        position: const LatLng(35, 139),
      ),
      MatchEvent(
        type: 'capture_zone_ack',
        atUtc: t0.add(const Duration(seconds: 2)),
        message: '確認 place:zoneA',
        position: const LatLng(35, 139),
      ),
      MatchEvent(
        type: 'capture_zone_bound',
        atUtc: t0.add(const Duration(seconds: 6)),
        message: '発動 place:zoneA',
        position: const LatLng(35, 139),
      ),
    ];
    final zones = ReplayCaptureZoneCatalog.fromEvents(events);
    expect(zones, hasLength(1));
    final visualPlaced = ReplayCaptureZoneCatalog.visualAt(
      zones.first,
      t0.add(const Duration(seconds: 1)),
    );
    expect(visualPlaced.visible, isTrue);
    final visualBound = ReplayCaptureZoneCatalog.visualAt(
      zones.first,
      t0.add(const Duration(milliseconds: 6300)),
    );
    expect(visualBound.boundFlash, isTrue);
  });

  test('gallery latest fetch merges remote', () async {
    final local = _sampleRecord();
    final remote = _sampleRecord(
      tracks: {
        ...local.tracks,
        'player_b': [
          TrajectorySample(
            atUtc: local.startedAtUtc,
            position: const LatLng(35.002, 139.002),
          ),
        ],
      },
    );
    final result = await MatchReplayLatestFetch.resolveForGallery(
      local: local,
      fetchRemote: () async => remote,
    );
    expect(result.source, MatchReplayFetchSource.remoteMerged);
    expect(result.record?.tracks.containsKey('player_b'), isTrue);
  });

  test('replay uses saved world profile', () {
    final r = _sampleRecord(worldProfile: WorldProfile.japaneseLuxury.name);
    expect(r.effectiveWorldProfile, WorldProfile.japaneseLuxury);
  });

  test('old records fallback world profile', () {
    final r = _sampleRecord();
    expect(r.effectiveWorldProfile, isA<WorldProfile>());
  });

  test('second game track kind dashed', () {
    final kind = ReplayTrackStyle.kindForTrackId(
      MatchTrackIds.spectralLocal,
      trackKinds: {MatchTrackIds.spectralLocal: ReplayTrackKind.spectral.name},
    );
    expect(kind, ReplayTrackKind.spectral);
    expect(ReplayTrackStyle.useDashedLine(kind), isTrue);
  });

  test('match recorder splits second game track', () {
    final rec = MatchRecorder(
      playAreaSnapshot:
          PlayArea.circle(center: const LatLng(0, 0), radiusMeters: 100),
      consentedToTrajectory: true,
      initialRunner: const LatLng(0, 0),
      initialOni: const LatLng(0.001, 0.001),
    );
    rec.tryAppendRunner(const LatLng(0.0005, 0.0005));
    rec.markRunnerEliminated(EliminationAftermathRule.spectralOperative);
    rec.tryAppendSecondGame(const LatLng(0.001, 0.001));
    final saved = rec.finalize(
      outcome: GameState.caughtByOni,
      reveals: const [],
      events: const [],
    );
    expect(saved, isNotNull);
    expect(saved!.tracks.containsKey(MatchTrackIds.spectralLocal), isTrue);
    expect(saved.tracks[MatchTrackIds.spectralLocal]!.length, greaterThanOrEqualTo(1));
    expect(
      saved.trackKinds[MatchTrackIds.spectralLocal],
      ReplayTrackKind.spectral.name,
    );
  });

  test('merger preserves world profile and track kinds', () {
    final local = _sampleRecord(
      worldProfile: WorldProfile.arg.name,
      trackKinds: {MatchTrackIds.runnerLocal: ReplayTrackKind.survivor.name},
    );
    final remote = _sampleRecord(worldProfile: WorldProfile.sport.name);
    final merged = MatchArchiveMerger.merge(local: local, remote: remote);
    expect(merged.worldProfile, WorldProfile.arg.name);
    expect(merged.trackKinds[MatchTrackIds.runnerLocal], 'survivor');
  });
}
