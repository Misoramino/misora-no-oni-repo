import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/features/game_map/presentation/match_start_roster_overlay.dart';

/// ロスター表示ポリシーの単体テスト（UI ではなくルールの期待値）。
void main() {
  bool shouldShowRoster({
    required bool rejoin,
    required bool shortCeremony,
    int elapsedSeconds = 0,
    int entryCount = 3,
  }) {
    if (shortCeremony || (rejoin && elapsedSeconds > 20)) return false;
    return entryCount > 0;
  }

  bool shouldShowOrbit({
    required bool rejoin,
    required bool shortCeremony,
    int elapsedSeconds = 0,
  }) {
    if (shortCeremony || (rejoin && elapsedSeconds > 12)) return false;
    return true;
  }

  group('match start presentation policy', () {
    test('short ceremony skips roster and orbit', () {
      expect(
        shouldShowRoster(rejoin: false, shortCeremony: true),
        isFalse,
      );
      expect(
        shouldShowOrbit(rejoin: false, shortCeremony: true),
        isFalse,
      );
    });

    test('late rejoin skips roster after 20s', () {
      expect(
        shouldShowRoster(rejoin: true, shortCeremony: false, elapsedSeconds: 25),
        isFalse,
      );
      expect(
        shouldShowOrbit(rejoin: true, shortCeremony: false, elapsedSeconds: 25),
        isFalse,
      );
    });

    test('roster entry carries role for display', () {
      const entry = MatchStartRosterEntry(
        label: 'テスト',
        role: PlayerRole.hunter,
      );
      expect(entry.role.displayName, '鬼');
    });
  });
}
