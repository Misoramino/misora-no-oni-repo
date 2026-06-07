import '../../progression/player_progress.dart';

/// リザルト画面の状況別ヒント（初回・初勝利など）。
abstract final class MatchResultHints {
  static String? afterMatch({
    required PlayerProgress before,
    required bool won,
  }) {
    if (won && before.wins == 0) {
      return '初勝利おめでとう！次は「ルームロビー」から友達を呼んで、'
          '本番のマルチで遊んでみましょう。';
    }
    if (before.matches == 0) {
      return '1試合完了！友達と遊ぶときはタイトルの「オンラインルーム」から参加できます。';
    }
    return null;
  }
}
