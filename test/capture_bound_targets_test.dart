import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merged capture bound targets combine placed uids and acks', () {
    final state = _CaptureBoundTargetMergeHarness();
    state.capturePlacedTargetsByPlace['zone-a'] = ['uid-1', 'uid-2'];
    state.captureAcksByPlace['zone-a'] = {'uid-2', 'uid-3'};

    final merged = state.mergedCaptureBoundTargets('zone-a');

    expect(merged, containsAll(['uid-1', 'uid-2', 'uid-3']));
    expect(merged.length, 3);
    expect(state.capturePlacedTargetsByPlace.containsKey('zone-a'), isFalse);
    expect(state.captureAcksByPlace.containsKey('zone-a'), isFalse);
  });

  test('merged capture bound targets returns empty when nothing recorded', () {
    final state = _CaptureBoundTargetMergeHarness();
    expect(state.mergedCaptureBoundTargets('missing'), isEmpty);
  });
}

/// package-private merge logic mirror for unit testing.
class _CaptureBoundTargetMergeHarness {
  final Map<String, List<String>> capturePlacedTargetsByPlace = {};
  final Map<String, Set<String>> captureAcksByPlace = {};

  List<String> mergedCaptureBoundTargets(String placeId) {
    final placed = capturePlacedTargetsByPlace.remove(placeId) ?? const [];
    final acked = captureAcksByPlace.remove(placeId)?.toList() ?? const [];
    return {...placed, ...acked}.toList(growable: false);
  }
}
