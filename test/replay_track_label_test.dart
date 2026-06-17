import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/replay/replay_track_kind.dart';
import 'package:oni_game/features/how_to_play/guide_terms.dart';
import 'package:oni_game/services/match_recorder.dart';

void main() {
  test('replay track labels avoid technical local wording', () {
    expect(
      ReplayTrackStyle.defaultTrackLabel(MatchTrackIds.oniLocal),
      GuideTerms.trueOni,
    );
    expect(
      ReplayTrackStyle.defaultTrackLabel(MatchTrackIds.runnerLocal),
      '自分',
    );
    expect(
      ReplayTrackStyle.defaultTrackTitle(MatchTrackIds.oniLocal),
      '${GuideTerms.trueOni}（再生）',
    );
  });
}
