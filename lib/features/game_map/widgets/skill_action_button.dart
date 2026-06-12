import 'package:flutter/material.dart';

class SkillActionButton extends StatefulWidget {
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
  State<SkillActionButton> createState() => _SkillActionButtonState();
}

class _SkillActionButtonState extends State<SkillActionButton> {
  bool _pinCd = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCd = widget.cooldownSeconds > 0;
    final onBuff = widget.buffSeconds != null && widget.buffSeconds! > 0;
    final enabled = widget.onPressed != null && !onCd;
    final showPinnedCd = _pinCd && onCd;
    final semanticLabel = _semanticLabel(
      onCd: onCd,
      onBuff: onBuff,
    );
    final compactFg = scheme.onSurface;
    final compactBg = scheme.surfaceContainerHighest.withValues(alpha: 0.98);
    final compactLabelFg = ThemeData.estimateBrightnessForColor(compactBg) ==
            Brightness.dark
        ? scheme.onSurface
        : const Color(0xFF1A1C1E);
    final btn = Material(
      color: widget.compact ? compactBg : null,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? widget.onPressed : null,
        onLongPress: onCd
            ? () => setState(() => _pinCd = !_pinCd)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: widget.compact ? 14 : 10,
            horizontal: widget.compact ? 6 : 8,
          ),
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.compact ? compactFg : null,
          ),
        ),
      ),
    );
    if (widget.compact) {
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
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: compactLabelFg.withValues(alpha: 0.92),
                ),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${widget.buffSeconds}s',
                  style: TextStyle(fontSize: 9, color: scheme.primary),
                ),
              )
            else if (showPinnedCd || onCd)
              ExcludeSemantics(
                child: Text(
                  showPinnedCd ? 'CD ${widget.cooldownSeconds}s' : '${widget.cooldownSeconds}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: showPinnedCd ? FontWeight.w700 : FontWeight.normal,
                    color: showPinnedCd
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
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
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${widget.buffSeconds}s',
                  style: const TextStyle(fontSize: 9),
                ),
              )
            else if (showPinnedCd || onCd)
              ExcludeSemantics(
                child: Text(
                  showPinnedCd
                      ? 'CD ${widget.cooldownSeconds}s'
                      : 'CD ${widget.cooldownSeconds}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: showPinnedCd ? FontWeight.bold : FontWeight.normal,
                    color: showPinnedCd ? scheme.primary : null,
                  ),
                ),
              )
            else if (widget.active)
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
      return '${widget.label}、効果残り${widget.buffSeconds}秒';
    }
    if (onCd) {
      return '${widget.label}、クールダウン${widget.cooldownSeconds}秒、長押しで固定表示';
    }
    if (widget.active && !widget.compact) {
      return '${widget.label}、作動中';
    }
    return widget.label;
  }
}
