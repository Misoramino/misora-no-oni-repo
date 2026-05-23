import 'player_role.dart';

abstract final class SkillIds {
  static const fakePosition = 'fake_position';
  static const fakeIntelReveal = 'fake_intel_reveal';
  static const captureZone = 'capture_zone';
  static const bodyThrow = 'body_throw';
  static const werewolfTransform = 'werewolf_transform';
}

String skillLabel(String id) => switch (id) {
      SkillIds.fakePosition => '偽位置',
      SkillIds.fakeIntelReveal => '偽情報暴露',
      SkillIds.captureZone => '捕獲結界',
      SkillIds.bodyThrow => '体投げ',
      SkillIds.werewolfTransform => '鬼化',
      _ => id,
    };

String skillShortLabel(String id) => switch (id) {
      SkillIds.fakePosition => '偽位置',
      SkillIds.fakeIntelReveal => '偽情報',
      SkillIds.captureZone => '結界',
      SkillIds.bodyThrow => '体投',
      SkillIds.werewolfTransform => '鬼化',
      _ => id,
    };

List<String> skillCandidatesForRole(PlayerRole role) => switch (role) {
      PlayerRole.runner => const [
          SkillIds.fakePosition,
          SkillIds.captureZone,
        ],
      PlayerRole.hunter => const [
          SkillIds.fakeIntelReveal,
          SkillIds.captureZone,
          SkillIds.bodyThrow,
        ],
      PlayerRole.werewolf => const [SkillIds.werewolfTransform],
    };
