/// ゲーム内の効果音イベント。
///
/// `assets/audio/sfx/<asset>.(wav|mp3|ogg)` が同梱されていればそれを再生し、
/// 無ければコード合成音（[SfxSynth]）にフォールバックする。
enum SfxId {
  uiTap('ui_tap'),
  uiBack('ui_back'),
  uiToggle('ui_toggle'),
  uiError('ui_error'),
  uiConfirm('ui_confirm'),
  matchStart('match_start'),
  matchWin('match_win'),
  matchLose('match_lose'),
  capture('capture'),
  eliminated('eliminated'),
  reveal('reveal'),
  anonReveal('anon_reveal'),
  skillCast('skill_cast'),
  skillReady('skill_ready'),
  denied('denied'),
  proximityWarning('proximity_warning'),
  proximityDanger('proximity_danger'),
  reward('reward'),
  unlock('unlock'),
  confetti('confetti');

  const SfxId(this.asset);

  /// 期待するアセットのベース名（拡張子なし）。
  final String asset;
}
