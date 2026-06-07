import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/inspector_feed_snapshot.dart';

void main() {
  test('InspectorFeedSnapshot parses feed doc', () {
    final snap = InspectorFeedSnapshot.tryParse('u1', {
      'lat': 35.68,
      'lng': 139.76,
      'nickname': 'Bob',
      'role': 'runner',
      'reportedAtUtc': '2026-01-01T12:00:00.000Z',
    });
    expect(snap, isNotNull);
    expect(snap!.uid, 'u1');
    expect(snap.nickname, 'Bob');
    expect(snap.lat, closeTo(35.68, 0.001));
  });
}
