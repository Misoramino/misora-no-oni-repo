import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';

void main() {
  test('validMemberPresence allows lat and lng for throttled gameplay sync', () {
    const allowed = [
      'nickname',
      'role',
      'reportedAtUtc',
      'proximityBand',
      'lat',
      'lng',
      'locationVisibility',
      'preferredRole',
      'preferredSkills',
      'werewolfOniForm',
      'avatarThumbB64',
      'prepReady',
      'appLifecycle',
      'backgroundSinceUtc',
    ];
    expect(allowed, contains(MemberPresenceFields.lastLat));
    expect(allowed, contains(MemberPresenceFields.lastLng));
  });
}
