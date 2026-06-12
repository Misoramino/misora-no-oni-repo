import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_weight.dart';
import 'package:oni_game/game/match_setup_summary.dart';
import 'package:oni_game/features/game_map/hud/match_phase.dart';

void main() {
  test('prep summary mentions player count', () {
    final line = MatchSetupSummary.prepSummaryLine(
      durationMinutes: 45,
      gimmickDensity: 1.0,
      participantCount: 5,
    );
    expect(line, contains('5 人'));
    expect(line, contains('45分'));
  });

  test('rules overview includes accusation weight', () {
    final line = MatchSetupSummary.rulesOverviewLine(
      durationMinutes: 30,
      accusationWeight: AccusationWeight.points,
      participantCount: 4,
      gimmickDensity: 0.72,
    );
    expect(line, contains('ポイント加算'));
    expect(line, contains('30分'));
  });

  test('match phase labels', () {
    expect(
      MatchPhase.label(
        accusationUnlocked: false,
        remainingSeconds: 2600,
        matchDurationSeconds: 2700,
      ),
      '隠密逃走',
    );
    expect(
      MatchPhase.label(
        accusationUnlocked: true,
        remainingSeconds: 900,
        matchDurationSeconds: 2700,
      ),
      '告発可',
    );
    expect(
      MatchPhase.label(
        accusationUnlocked: true,
        remainingSeconds: 480,
        matchDurationSeconds: 2700,
      ),
      '残り8分',
    );
  });
}
