import 'package:flutter/material.dart';

class SkillActionButton extends StatelessWidget {
  const SkillActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.cooldownSeconds = 0,
    this.buffSeconds,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final int cooldownSeconds;
  final int? buffSeconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onCd = cooldownSeconds > 0;
    final onBuff = buffSeconds != null && buffSeconds! > 0;
    final enabled = onPressed != null && !onCd;
    final btn = Material(
      color: compact ? Colors.white.withValues(alpha: 0.14) : null,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 6 : 10,
            horizontal: compact ? 4 : 8,
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 22,
            color: compact ? Colors.white : null,
          ),
        ),
      ),
    );
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: double.infinity, child: btn),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: Colors.white70),
          ),
          if (onBuff)
            Text('${buffSeconds}s', style: const TextStyle(fontSize: 8))
          else if (onCd)
            Text('$cooldownSeconds', style: const TextStyle(fontSize: 8)),
        ],
      );
    }
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
          if (onBuff)
            Text('${buffSeconds}s', style: const TextStyle(fontSize: 9))
          else if (onCd)
            Text('CD $cooldownSeconds', style: const TextStyle(fontSize: 9))
          else if (active)
            const Text('作動中', style: TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
