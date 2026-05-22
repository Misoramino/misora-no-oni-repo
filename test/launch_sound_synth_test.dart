import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/theme/launch_sound_synth.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  test('synthesized wav has RIFF header and data', () {
    for (final p in WorldProfile.values) {
      final wav = LaunchSoundSynth.wavFor(p);
      expect(wav.length, greaterThan(1000));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    }
  });

  test('launch sounds are long enough to read the theme', () {
    const minMs = 550;
    const bytesPerMs = 22050 * 2 / 1000;
    final minBytes = 44 + (minMs * bytesPerMs).round();
    for (final p in WorldProfile.values) {
      expect(
        LaunchSoundSynth.wavFor(p).length,
        greaterThan(minBytes),
        reason: '${p.label} launch sound should be at least ~${minMs}ms',
      );
    }
  });
}
