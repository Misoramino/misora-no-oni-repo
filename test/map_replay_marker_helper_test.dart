import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/map/map_marker_kind.dart';
import 'package:oni_game/features/game_map/map/map_replay_marker_helper.dart';
import 'package:oni_game/services/match_recorder.dart';

void main() {
  test('track ids map to player and oni kinds', () {
    expect(
      MapReplayMarkerHelper.forTrackId(MatchTrackIds.runnerLocal),
      MapMarkerKind.player,
    );
    expect(
      MapReplayMarkerHelper.forTrackId(MatchTrackIds.oniLocal),
      MapMarkerKind.oni,
    );
  });

  test('reveal event types flash and map to reveal marker', () {
    expect(MapReplayMarkerHelper.isRevealFlashType('area_reveal'), isTrue);
    expect(
      MapReplayMarkerHelper.forEventType('fake_intel_reveal'),
      MapMarkerKind.reveal,
    );
    expect(
      MapReplayMarkerHelper.forEventType('info_broker'),
      MapMarkerKind.infoBroker,
    );
  });
}
