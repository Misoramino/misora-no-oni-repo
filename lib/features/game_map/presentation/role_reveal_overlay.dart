import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/runner_modifier.dart';
import '../../../game/werewolf_faction_logic.dart';
import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../theme/world_profile.dart';
import '../../../widgets/motion_helpers.dart';
import '../widgets/role_briefing_dialog.dart';

/// Among Us 風: 役職カードを短時間表示して自動で閉じる（タップ不要）。
Future<void> showAutoRoleRevealOverlay({
  required BuildContext context,
  required PlayerRole role,
  required List<String> skillLabels,
  WorldProfile? worldProfile,
  FactionSide? werewolfCurrentFaction,
  RunnerModifier runnerModifier = RunnerModifier.none,
  Duration displayDuration = const Duration(seconds: 4),
}) async {
  if (!context.mounted) return;
  final reduce = MotionHelpers.reduceMotionOf(context);
  final hold =
      reduce ? const Duration(milliseconds: 900) : displayDuration;

  final completer = Completer<void>();

  unawaited(
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, animation, secondaryAnimation) => _RoleRevealCard(
        role: role,
        skillLabels: skillLabels,
        worldProfile: worldProfile ?? WorldProfile.urbanHorror,
        werewolfCurrentFaction: werewolfCurrentFaction,
        runnerModifier: runnerModifier,
        autoCloseAfter: hold,
        onClosed: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    ).whenComplete(() {
      if (!completer.isCompleted) completer.complete();
    }),
  );

  await completer.future;
}

class _RoleRevealCard extends StatefulWidget {
  const _RoleRevealCard({
    required this.role,
    required this.skillLabels,
    required this.worldProfile,
    this.werewolfCurrentFaction,
    this.runnerModifier = RunnerModifier.none,
    this.autoCloseAfter,
    this.onClosed,
  });

  final PlayerRole role;
  final List<String> skillLabels;
  final WorldProfile worldProfile;
  final FactionSide? werewolfCurrentFaction;
  final RunnerModifier runnerModifier;
  final Duration? autoCloseAfter;
  final VoidCallback? onClosed;

  @override
  State<_RoleRevealCard> createState() => _RoleRevealCardState();
}

class _RoleRevealCardState extends State<_RoleRevealCard>
    with SingleTickerProviderStateMixin {
  Timer? _closeTimer;
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    final delay = widget.autoCloseAfter;
    if (delay != null) {
      _closeTimer = Timer(delay, _close);
    }
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onClosed?.call();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = RoleBriefingCatalog.matchStartBriefing(
      widget.role,
      werewolfFaction: widget.werewolfCurrentFaction,
      runnerModifier: widget.runnerModifier,
    );
    final roleAccent = roleAccentColor(widget.role);
    final pack = WorldPresentationCatalog.of(widget.worldProfile);
    final accent = Color.lerp(pack.accent, roleAccent, 0.45)!;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(
            CurvedAnimation(parent: _entry, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: pack.panelSurfaceOpaque,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon(widget.role), size: 56, color: accent),
                  const SizedBox(height: 14),
                  Text(
                    'あなたは${widget.role.displayName}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    start.tagline,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: pack.textOnPanel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    start.winLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: pack.textOnPanel.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.skillLabels.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      '装備: ${widget.skillLabels.join(' / ')}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: pack.textOnPanel.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'まもなく開始…',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent.withValues(alpha: 0.85),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
