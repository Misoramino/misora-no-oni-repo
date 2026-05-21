import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../session/launch_branding_prefs.dart';
import '../../theme/launch_sound_synth.dart';
import '../../theme/world_profile.dart';

/// 起動時のみ使う短い効果音（合成 WAV、~300ms）。
class LaunchSoundPlayer {
  LaunchSoundPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _played = false;

  Future<void> playIfEnabled(WorldProfile profile) async {
    if (_played || kIsWeb) return;
    final enabled = await LaunchBrandingPrefs.loadSoundEnabled();
    if (!enabled) return;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.72);
      final bytes = LaunchSoundSynth.wavFor(profile);
      await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      _played = true;
    } catch (e, st) {
      debugPrint('LaunchSoundPlayer: $e\n$st');
    }
  }

  Future<void> dispose() => _player.dispose();
}
