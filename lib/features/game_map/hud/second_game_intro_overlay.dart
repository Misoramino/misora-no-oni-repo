import 'package:flutter/material.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/elimination_role_copy.dart';
import '../../../theme/world_profile.dart';

/// 脱落直後に3秒表示する第二ゲーム導入オーバーレイ。
Future<void> showSecondGameIntroOverlay(
  BuildContext context, {
  required EliminationAftermathRule rule,
  required WorldProfile worldProfile,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => _SecondGameIntroOverlay(
      rule: rule,
      worldProfile: worldProfile,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class _SecondGameIntroOverlay extends StatefulWidget {
  const _SecondGameIntroOverlay({
    required this.rule,
    required this.worldProfile,
  });

  final EliminationAftermathRule rule;
  final WorldProfile worldProfile;

  @override
  State<_SecondGameIntroOverlay> createState() =>
      _SecondGameIntroOverlayState();
}

class _SecondGameIntroOverlayState extends State<_SecondGameIntroOverlay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final copy = EliminationRoleCopy.forProfile(
      widget.worldProfile,
      widget.rule,
    );
    final leg = MapHudMapPanelLegibility.resolve(scheme, widget.worldProfile);
    final tips = _tipsForRule(widget.rule, copy);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: leg.panelBg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '第二ゲームへ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: leg.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.roleTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: leg.title,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.roleSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: leg.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...tips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('続ける'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使える施設が地図で強調表示されます',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
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

  static List<String> _tipsForRule(
    EliminationAftermathRule rule,
    EliminationRoleCopy copy,
  ) {
    return switch (rule) {
      EliminationAftermathRule.spectralOperative => [
        '${copy.jackSiteLabel}で監視ジャックが使えます',
        '告発施設の近くで陣取りチャージ（有効施設+1）',
      ],
      EliminationAftermathRule.revenantOni => [
        '告発施設で妨害チャージ（有効施設-1）',
        '監視カメラを停止できます',
      ],
      EliminationAftermathRule.ghostSpectator => [
        '観戦モード — 全体のざっくり位置を確認',
      ],
      EliminationAftermathRule.joinOni => [
        '鬼側合流 — 索敵支援でざっくり位置を共有',
      ],
    };
  }
}
