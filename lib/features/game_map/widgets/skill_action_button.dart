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
    final scheme = Theme.of(context).colorScheme;
    final onCd = cooldownSeconds > 0;
    final onBuff = buffSeconds != null && buffSeconds! > 0;
    final enabled = onPressed != null && !onCd;
    final semanticLabel = _semanticLabel(
      onCd: onCd,
      onBuff: onBuff,
    );
    final compactFg = scheme.onSurface;
    final compactBg = scheme.surfaceContainerHighest.withValues(alpha: 0.98);
    final btn = Material(
      color: compact ? compactBg : null,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 14 : 10,
            horizontal: compact ? 6 : 8,
          ),
          child: Icon(
            icon,
            size: 22,
            color: compact ? compactFg : null,
          ),
        ),
      ),
    );
    if (compact) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ExcludeSemantics(child: btn),
            ),
            ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${buffSeconds}s',
                  style: TextStyle(fontSize: 9, color: scheme.primary),
                ),
              )
            else if (onCd)
              ExcludeSemantics(
                child: Text(
                  '$cooldownSeconds',
                  style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: btn),
            const SizedBox(height: 2),
            ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${buffSeconds}s',
                  style: const TextStyle(fontSize: 9),
                ),
              )
            else if (onCd)
              ExcludeSemantics(
                child: Text(
                  'CD $cooldownSeconds',
                  style: const TextStyle(fontSize: 9),
                ),
              )
            else if (active)
              ExcludeSemantics(
                child: const Text('作動中', style: TextStyle(fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }

  String _semanticLabel({
    required bool onCd,
    required bool onBuff,
  }) {
    if (onBuff) {
      return '$label、効果残り$buffSeconds秒';
    }
    if (onCd) {
      return '$label、クールダウン$cooldownSeconds秒';
    }
    if (active && !compact) {
      return '$label、作動中';
    }
    return label;
  }
}
