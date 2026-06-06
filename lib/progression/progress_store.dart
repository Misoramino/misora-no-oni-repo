import 'package:shared_preferences/shared_preferences.dart';

import '../game/werewolf_faction_logic.dart';
import 'player_progress.dart';
import 'player_title.dart';

/// 1 試合分の記録結果。新たに解放された称号も返す。
class ProgressUpdate {
  const ProgressUpdate({required this.progress, required this.newlyUnlocked});

  final PlayerProgress progress;
  final List<PlayerTitle> newlyUnlocked;
}

/// 累積戦績の読み書き（端末ローカル）。
abstract final class ProgressStore {
  static const _key = 'player_progress_v1';

  static Future<PlayerProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const PlayerProgress();
    return PlayerProgress.decode(raw);
  }

  static Future<void> _save(PlayerProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, p.encode());
  }

  /// 1 試合の結果を記録し、更新後の戦績と新規称号を返す。
  static Future<ProgressUpdate> recordMatch({
    required bool won,
    FactionSide? faction,
  }) async {
    final before = await load();
    final nextStreak = won ? before.currentStreak + 1 : 0;
    var updated = before.copyWith(
      matches: before.matches + 1,
      wins: won ? before.wins + 1 : before.wins,
      losses: won ? before.losses : before.losses + 1,
      winsHuman: won && faction == FactionSide.humanTeam
          ? before.winsHuman + 1
          : before.winsHuman,
      winsOni: won && faction == FactionSide.oniTeam
          ? before.winsOni + 1
          : before.winsOni,
      currentStreak: nextStreak,
      bestStreak:
          nextStreak > before.bestStreak ? nextStreak : before.bestStreak,
    );

    final unlocked = PlayerTitles.unlockedIds(updated);
    final newlyIds = unlocked.difference(before.unlockedTitleIds);
    updated = updated.copyWith(unlockedTitleIds: unlocked);

    await _save(updated);
    return ProgressUpdate(
      progress: updated,
      newlyUnlocked: PlayerTitles.byIds(newlyIds),
    );
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
