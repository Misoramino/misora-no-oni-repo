/// ゲーム状態に応じた音楽演出フェーズ（ロジックは変更しない）。
///
/// ## 状態遷移（典型）
///
/// ```
/// title ──► gallery / lobby ──► preMatchPresentation ──► matchCountdown
///   ▲                              │
///   │                              ▼
/// returnTitle ◄── result* ◄── match ◄──┘
///                    ▲         │ danger / accusation* / final*
///                    │         ▼
///                 replay (MatchReplayScreen)
/// ```
///
/// * `resultVictory` | `resultLose` | `resultDraw` | `resultSpectator`
/// * `accusationAvailable` → `accusationSequence`
/// * `finalFiveMinutes` → `finalMinute` → `finalTenSeconds`
///
/// 実装: [WorldAudioDirector] — `lib/audio/world_audio_director.dart`
/// 遷移表の詳細: `lib/audio/README.md`
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

  /// 試合記録のタイムラプス再生（回想向け・低音量）。
  replay,
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
        WorldAudioState.replay => 'Replay',
      };
}

/// [WorldAudioDirector] がカバーすべき全状態。
const kWorldAudioDirectorStates = WorldAudioState.values;
