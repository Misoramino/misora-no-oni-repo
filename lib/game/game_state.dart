enum GameState {
  waiting,
  running,
  runnerWin,
  caughtByOni,
}

extension GameStateText on GameState {
  String get label {
    switch (this) {
      case GameState.waiting:
        return '待機中';
      case GameState.running:
        return 'ゲーム中';
      case GameState.runnerWin:
        return '逃走成功';
      case GameState.caughtByOni:
        return '捕まった';
    }
  }
}
