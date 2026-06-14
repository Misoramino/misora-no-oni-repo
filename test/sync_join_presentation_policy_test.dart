import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_config.dart';

bool shouldUseRemoteSyncJoinFullPresentation(int elapsedSeconds) =>
    elapsedSeconds <= GameConfig.syncJoinFullPresentationMaxSeconds;

bool shouldShowRoleBriefingOnSyncJoin(int elapsedSeconds) =>
    elapsedSeconds <= GameConfig.syncJoinRoleBriefingMaxSeconds;

void main() {
  test('sync join full presentation within 45 seconds', () {
    expect(shouldUseRemoteSyncJoinFullPresentation(10), isTrue);
    expect(shouldUseRemoteSyncJoinFullPresentation(45), isTrue);
    expect(shouldUseRemoteSyncJoinFullPresentation(46), isFalse);
  });

  test('sync join role briefing within 90 seconds', () {
    expect(shouldShowRoleBriefingOnSyncJoin(60), isTrue);
    expect(shouldShowRoleBriefingOnSyncJoin(90), isTrue);
    expect(shouldShowRoleBriefingOnSyncJoin(91), isFalse);
  });
}
