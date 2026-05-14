import 'firestore_room_blueprint.dart';

/// Firestore へのプレゼンス書き込みを間引く（無料枠向け）。
class PresenceThrottle {
  PresenceThrottle({required this.minIntervalMs});

  final int minIntervalMs;
  DateTime? _last;

  bool requestSlot() {
    final now = DateTime.now();
    if (_last == null ||
        now.difference(_last!).inMilliseconds >= minIntervalMs) {
      _last = now;
      return true;
    }
    return false;
  }
}

/// 緊迫時は [PresenceSyncBudget.tensionMinIntervalMs]、通常は [calm]。
PresenceThrottle calmPresenceThrottle() =>
    PresenceThrottle(minIntervalMs: PresenceSyncBudget.calmMinIntervalMs);

PresenceThrottle tensionPresenceThrottle() =>
    PresenceThrottle(minIntervalMs: PresenceSyncBudget.tensionMinIntervalMs);
