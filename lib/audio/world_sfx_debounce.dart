import '../theme/world_profile.dart';
import 'world_sfx_preview.dart';

/// 世界観 SE の連打抑制（同一 profile + 種類の最小間隔）。
class WorldSfxDebounce {
  WorldSfxDebounce([DateTime Function()? clock])
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastPlayed = {};

  /// 再生してよければ `true` を返し、ゲートを更新する。
  bool tryAcquire(
    WorldProfile profile,
    WorldSfxPreviewKind kind, {
    int? debounceMs,
  }) {
    final key = '${profile.storageName}:${kind.name}';
    final now = _clock();
    final last = _lastPlayed[key];
    final gap = Duration(milliseconds: debounceMs ?? kind.debounceMs);
    if (last != null && now.difference(last) < gap) {
      return false;
    }
    _lastPlayed[key] = now;
    return true;
  }

  void reset() => _lastPlayed.clear();
}
