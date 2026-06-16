/// ゲーム状態に応じた音楽演出フェーズ（ロジックは変更しない）。
enum WorldAudioState {
  title,
  gallery,
  lobby,
  preMatchPresentation,
  matchCountdown,
  match,
  finalFiveMinutes,
  finalMinute,
  finalTenSeconds,
  danger,
  accusationAvailable,
  accusationSequence,
  resultVictory,
  resultLose,
  resultDraw,
  resultSpectator,
  returnTitle,
}

extension WorldAudioStateLabels on WorldAudioState {
  String get debugLabel => switch (this) {
        WorldAudioState.title => 'Title',
        WorldAudioState.gallery => 'Gallery',
        WorldAudioState.lobby => 'Lobby',
        WorldAudioState.preMatchPresentation => 'PreMatchPresentation',
        WorldAudioState.matchCountdown => 'MatchCountdown',
        WorldAudioState.match => 'Match',
        WorldAudioState.finalFiveMinutes => 'FinalMinute5',
        WorldAudioState.finalMinute => 'FinalMinute1',
        WorldAudioState.finalTenSeconds => 'FinalTenSeconds',
        WorldAudioState.danger => 'Danger',
        WorldAudioState.accusationAvailable => 'AccusationAvailable',
        WorldAudioState.accusationSequence => 'AccusationSequence',
        WorldAudioState.resultVictory => 'ResultVictory',
        WorldAudioState.resultLose => 'ResultLose',
        WorldAudioState.resultDraw => 'ResultDraw',
        WorldAudioState.resultSpectator => 'ResultSpectator',
        WorldAudioState.returnTitle => 'ReturnTitle',
      };
}

/// [WorldAudioDirector] がカバーすべき全状態。
const kWorldAudioDirectorStates = WorldAudioState.values;
