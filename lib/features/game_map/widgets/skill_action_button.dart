import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';

class SkillActionButton extends StatefulWidget {
  const SkillActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.cooldownSeconds = 0,
    this.buffSeconds,
    this.compact = false,
    this.blocked = false,
    this.auxLine,
    this.worldProfile,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final int cooldownSeconds;
  final int? buffSeconds;
  final bool compact;
  final bool blocked;
  final String? auxLine;
  final WorldProfile? worldProfile;

  @override
  State<SkillActionButton> createState() => _SkillActionButtonState();
}

class _SkillActionButtonState extends State<SkillActionButton> {
  bool _pinCd = false;

  MapHudRunningLegibility _leg(BuildContext context) {
    final profile = widget.worldProfile ?? WorldProfile.horror;
    return MapHudRunningLegibility.resolve(
      Theme.of(context).colorScheme,
      profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final leg = _leg(context);
    final onCd = widget.cooldownSeconds > 0;
    final onBuff = widget.buffSeconds != null && widget.buffSeconds! > 0;
    final enabled = widget.onPressed != null && !onCd && !widget.blocked;
    final showPinnedCd = _pinCd && onCd;
    final semanticLabel = _semanticLabel(
      onCd: onCd,
      onBuff: onBuff,
    );
    final btn = Material(
      color: widget.compact ? leg.skillButtonBg : null,
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
            color: widget.compact
                ? (enabled ? leg.skillButtonFg : leg.skillButtonMuted)
                : leg.icon,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: leg.skillButtonFg,
                ),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${widget.buffSeconds}s',
                  style: TextStyle(fontSize: 11, color: leg.accent),
                ),
              )
            else if (widget.blocked)
              ExcludeSemantics(
                child: Text(
                  '回収待ち',
                  style: TextStyle(fontSize: 11, color: leg.skillButtonMuted),
                ),
              )
            else if (widget.auxLine != null)
              ExcludeSemantics(
                child: Text(
                  widget.auxLine!,
                  style: TextStyle(fontSize: 11, color: leg.skillButtonMuted),
                ),
              )
            else if (showPinnedCd || onCd)
              ExcludeSemantics(
                child: Text(
                  'あと${widget.cooldownSeconds}s',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: showPinnedCd ? FontWeight.w700 : FontWeight.normal,
                    color: showPinnedCd ? leg.accent : leg.skillButtonMuted,
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
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: leg.body,
                ),
              ),
            ),
            if (onBuff)
              ExcludeSemantics(
                child: Text(
                  '${widget.buffSeconds}s',
                  style: TextStyle(fontSize: 11, color: leg.accent),
                ),
              )
            else if (widget.blocked)
              ExcludeSemantics(
                child: Text(
                  '回収待ち',
                  style: TextStyle(fontSize: 11, color: leg.muted),
                ),
              )
            else if (widget.auxLine != null)
              ExcludeSemantics(
                child: Text(
                  widget.auxLine!,
                  style: TextStyle(fontSize: 11, color: leg.muted),
                ),
              )
            else if (showPinnedCd || onCd)
              ExcludeSemantics(
                child: Text(
                  'あと${widget.cooldownSeconds}s',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: showPinnedCd ? FontWeight.bold : FontWeight.normal,
                    color: showPinnedCd ? leg.accent : leg.muted,
                  ),
                ),
              )
            else if (widget.active)
              ExcludeSemantics(
                child: Text(
                  '作動中',
                  style: TextStyle(fontSize: 9, color: leg.accent),
                ),
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
    if (widget.blocked) {
      return '${widget.label}、体投げの回収待ち';
    }
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
