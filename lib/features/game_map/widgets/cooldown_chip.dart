import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';

class CooldownChip extends StatelessWidget {
  const CooldownChip({
    required this.label,
    required this.seconds,
    this.worldProfile,
    super.key,
  });

  final String label;
  final int seconds;
  final WorldProfile? worldProfile;

  @override
  Widget build(BuildContext context) {
    final profile = worldProfile ?? WorldProfile.horror;
    final leg = MapHudRunningLegibility.resolve(
      Theme.of(context).colorScheme,
      profile,
    );
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: leg.cdChipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: leg.border.withValues(alpha: 0.45)),
      ),
      child: Text(
        seconds > 0 ? '$label ${seconds}s' : label,
        style: TextStyle(fontSize: 11, color: leg.cdChipFg),
      ),
    );
  }
}
