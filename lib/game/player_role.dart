enum PlayerRole {
  runner('runner'),
  hunter('hunter'),
  werewolf('werewolf');

  const PlayerRole(this.label);
  final String label;
}

extension PlayerRoleUi on PlayerRole {
  String get displayName => switch (this) {
        PlayerRole.runner => '逃走者',
        PlayerRole.hunter => '鬼',
        PlayerRole.werewolf => '人狼',
      };
}

const assignablePlayerRoles = [
  PlayerRole.runner,
  PlayerRole.hunter,
  PlayerRole.werewolf,
];
