import 'package:flutter/material.dart';

import '../../game_map/widgets/how_to_play_diagrams.dart';
import '../guide_diagram_type.dart';
import '../guide_terms.dart';

/// [GuideDiagramType] に応じた図解 Widget を返す。
Widget buildGuideDiagram(BuildContext context, GuideDiagramType type) {
  return switch (type) {
    GuideDiagramType.informationTypes => const InformationTypesDiagram(),
    GuideDiagramType.infoStrength => const InformationStrengthDiagram(),
    GuideDiagramType.infoTraceChain => const TraceChainDiagram(),
    GuideDiagramType.combatDanger => const CombatDangerDiagram(),
    GuideDiagramType.outsideAreaFlow => const OutsideAreaFlowDiagram(),
    GuideDiagramType.accusationFlow => const AccusationFlowDiagram(),
    GuideDiagramType.secondGameBranch => const SecondGameBranchDiagram(),
    GuideDiagramType.factionWin => const FactionWinDiagram(),
    GuideDiagramType.introClues => const IntroCluesDiagram(),
    GuideDiagramType.facilityRoles => const FacilityRolesDiagram(),
    GuideDiagramType.mapConcept => const HelpMapConceptDiagram(),
    GuideDiagramType.werewolfNotOni => const WerewolfNotOniDiagram(),
    GuideDiagramType.skillPlacement => const SkillPlacementDiagram(),
    GuideDiagramType.roleOverview => const RoleOverviewDiagram(),
    GuideDiagramType.skillOverview => const SkillOverviewDiagram(),
    GuideDiagramType.onlineMatch => const OnlineMatchDiagram(),
  };
}

// --- shared helpers ---

class _DiagramMiniCard extends StatelessWidget {
  const _DiagramMiniCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownArrow extends StatelessWidget {
  const _DownArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(
        Icons.arrow_downward_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _DangerBand extends StatelessWidget {
  const _DangerBand({
    required this.color,
    required this.label,
    required this.note,
    this.emphasizeNotElimination = false,
  });

  final Color color;
  final String label;
  final String note;
  final bool emphasizeNotElimination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),
                if (emphasizeNotElimination)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '脱落ではありません',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- priority 5 diagrams ---

/// DIA-INFO-003: 情報の強さ
class InformationStrengthDiagram extends StatelessWidget {
  const InformationStrengthDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    const rows = [
      (Icons.person_pin_circle_outlined, '名前付き暴露', 1.0),
      (Icons.storefront_outlined, '情報屋ヒント', 0.82),
      (Icons.videocam_outlined, '監視カメラ', 0.64),
      (Icons.help_outline, GuideTerms.anonTrace, 0.46),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '強い情報',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(row.$1, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(row.$2, style: theme.textTheme.bodySmall),
                ),
                SizedBox(
                  width: 72,
                  child: LinearProgressIndicator(
                    value: row.$3,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        Text(
          '弱い情報',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${GuideTerms.anonTrace}は1つだけでは弱いですが、'
          '複数つなぐと移動方向が見えます。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// DIA-INFO-004: 痕跡をつなぐ
class TraceChainDiagram extends StatelessWidget {
  const TraceChainDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Column(
            children: [
              Icon(Icons.help_outline, color: scheme.tertiary, size: 22),
              const SizedBox(height: 2),
              Text('？', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          if (i < 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.outline,
              ),
            ),
        ],
      ],
    );
  }
}

/// DIA-ONLINE-001: 試合中止と記録
class OnlineMatchDiagram extends StatelessWidget {
  const OnlineMatchDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const HelpFlowDiagram(
          steps: [
            (icon: Icons.how_to_vote_outlined, label: '過半数で中止', color: null),
            (
              icon: Icons.block_outlined,
              label: '勝敗・戦績なし',
              color: Color(0xFFE88B2E),
            ),
            (
              icon: Icons.photo_library_outlined,
              label: '同意時はギャラリー',
              color: null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '再接続時は経過時間や脱落後の状態が復元されます。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// DIA-INFO-002: 名前付き暴露と匿名痕跡
class InformationTypesDiagram extends StatelessWidget {
  const InformationTypesDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 300;
        final named = _DiagramMiniCard(
          icon: Icons.person_pin_circle_outlined,
          iconColor: scheme.primary,
          title: GuideTerms.namedReveal,
          lines: const [
            '「○○がここにいた」',
            '名前あり・強い情報',
          ],
          footer: '今もそこにいるとは限りません',
        );
        final anon = _DiagramMiniCard(
          icon: Icons.help_outline,
          iconColor: scheme.tertiary,
          title: GuideTerms.anonTrace,
          lines: const [
            '「誰かがここにいた」',
            '名前なし・推理の材料',
          ],
          footer: '複数つなぐと移動方向が見えます',
        );
        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: named),
              const SizedBox(width: 8),
              Expanded(child: anon),
            ],
          );
        }
        return Column(
          children: [
            named,
            const SizedBox(height: 8),
            anon,
          ],
        );
      },
    );
  }
}

/// DIA-COMBAT-001: 鬼との距離と危険度
class CombatDangerDiagram extends StatelessWidget {
  const CombatDangerDiagram({super.key});

  static const _capture = Color(0xFFD64545);
  static const _restraint = Color(0xFFE88B2E);
  static const _panic = Color(0xFFE6B422);
  static const _safe = Color(0xFF1FA98A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlight_round, color: theme.colorScheme.error, size: 22),
            const SizedBox(width: 6),
            Text(
              '鬼（近いほど危険）',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const _DownArrow(),
        const _DangerBand(
          color: _capture,
          label: '🔴 捕獲',
          note: '至近まで近づくと脱落',
        ),
        const _DangerBand(
          color: _restraint,
          label: '🟠 拘束',
          note: '円の外へ出て逃げ切ればセーフ（戻る必要はない）',
        ),
        const _DangerBand(
          color: _panic,
          label: '🟡 ${GuideTerms.panic}',
          note: '${GuideTerms.anonTrace}が出る。追われやすい',
          emphasizeNotElimination: true,
        ),
        const _DangerBand(
          color: _safe,
          label: '🟢 安全',
          note: '距離を保てば手がかりを残しにくい',
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run_rounded, color: _safe, size: 20),
            const SizedBox(width: 6),
            Text(
              GuideTerms.runner,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }
}

/// DIA-AREA-001: エリア外の危険段階
class OutsideAreaFlowDiagram extends StatelessWidget {
  const OutsideAreaFlowDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
            color: scheme.primaryContainer.withValues(alpha: 0.25),
          ),
          child: Column(
            children: [
              Text(
                'プレイエリア内',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 16),
              Text(
                '境界を越える',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const _DownArrow(),
        const HelpFlowDiagram(
          steps: [
            (icon: Icons.timer_outlined, label: '猶予', color: null),
            (
              icon: Icons.person_pin_circle_outlined,
              label: '名前付き暴露',
              color: null,
            ),
            (
              icon: Icons.repeat_rounded,
              label: '再暴露',
              color: null,
            ),
            (
              icon: Icons.logout_rounded,
              label: '長時間で脱落',
              color: Color(0xFFD64545),
            ),
          ],
        ),
        Text(
          '即脱落ではありません。${GuideTerms.trueOni}も同様に段階的に危険です。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// DIA-ACCUSE-001: 告発の流れ
class AccusationFlowDiagram extends StatelessWidget {
  const AccusationFlowDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const HelpFlowDiagram(
          steps: [
            (icon: Icons.radar_outlined, label: '痕跡を読む', color: null),
            (
              icon: Icons.psychology_outlined,
              label: '${GuideTerms.trueOni}を推理',
              color: null,
            ),
            (
              icon: Icons.account_balance_outlined,
              label: '告発施設へ',
              color: null,
            ),
            (
              icon: Icons.emoji_events_outlined,
              label: '正解なら勝利',
              color: Color(0xFF1FA98A),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '告発の対象は${GuideTerms.trueOni}です。'
          '${GuideTerms.werewolf}は${GuideTerms.trueOni}ではありません。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// DIA-SECOND-001: 脱落後の分岐
class SecondGameBranchDiagram extends StatelessWidget {
  const SecondGameBranchDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const humanColor = Color(0xFF1FA98A);
    const oniColor = Color(0xFFD64545);
    return Column(
      children: [
        _DiagramMiniCard(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: theme.colorScheme.outline,
          title: '脱落',
          lines: const ['捕獲・告発失敗・エリア外など'],
        ),
        const _DownArrow(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DiagramMiniCard(
                icon: Icons.sensors_outlined,
                iconColor: humanColor,
                title: GuideTerms.echoForm,
                lines: const [
                  '人側として脱落',
                  '監視端子ジャック',
                  '告発施設の陣取り',
                ],
                footer: '味方を助ける（観戦ではない）',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DiagramMiniCard(
                icon: Icons.blur_on_rounded,
                iconColor: oniColor,
                title: GuideTerms.vengefulShadow,
                lines: const [
                  '鬼側として脱落',
                  '告発施設の妨害',
                  '監視カメラ停止',
                ],
                footer: '相手を妨害（観戦ではない）',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${GuideTerms.secondGame}でも試合の勝敗に関われます。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- supplementary section diagrams ---

/// DIA-CORE-001 / intro: ライブ位置は見えない
class IntroCluesDiagram extends StatelessWidget {
  const IntroCluesDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(Icons.location_off_outlined, size: 28, color: scheme.error),
              const SizedBox(height: 4),
              Text(
                '相手のライブ位置',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                '基本見えません',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const _DownArrow(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: const [
            _ClueChip(icon: Icons.person_pin_circle_outlined, label: '名前付き暴露'),
            _ClueChip(icon: Icons.help_outline, label: '匿名痕跡'),
            _ClueChip(icon: Icons.videocam_outlined, label: '監視カメラ'),
            _ClueChip(icon: Icons.storefront_outlined, label: '情報屋'),
          ],
        ),
      ],
    );
  }
}

class _ClueChip extends StatelessWidget {
  const _ClueChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: scheme.primary),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// DIA-WIN-001: 勝敗条件（本鬼表記）
class FactionWinDiagram extends StatelessWidget {
  const FactionWinDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    const humanColor = Color(0xFF1FA98A);
    final oniColor = Theme.of(context).colorScheme.error;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FactionPanel(
                color: humanColor,
                icon: Icons.directions_run_rounded,
                title: GuideTerms.humanFaction,
                lines: const [
                  '制限時間まで生存',
                  '${GuideTerms.trueOni}を告発',
                  '${GuideTerms.trueOni}が0人',
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
              child: Text(
                'VS',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Expanded(
              child: _FactionPanel(
                color: oniColor,
                icon: Icons.nightlight_round,
                title: GuideTerms.oniFaction,
                lines: const [
                  '逃走者を捕獲',
                  '人側生存者を0人',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${GuideTerms.werewolf}が残っていても、'
          '${GuideTerms.trueOni}が0人なら${GuideTerms.humanFaction}勝利',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FactionPanel extends StatelessWidget {
  const _FactionPanel({
    required this.color,
    required this.icon,
    required this.title,
    required this.lines,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '・$line',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// DIA-FACILITY-001
class FacilityRolesDiagram extends StatelessWidget {
  const FacilityRolesDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cellW = w >= 280 ? (w - 8) / 2 : w;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FacilityTile(
              width: cellW,
              icon: Icons.shield_outlined,
              label: '安全地帯',
              note: '暴露を防ぐ',
            ),
            _FacilityTile(
              width: cellW,
              icon: Icons.storefront_outlined,
              label: '情報屋',
              note: '手がかりを得る',
            ),
            _FacilityTile(
              width: cellW,
              icon: Icons.videocam_outlined,
              label: '監視カメラ',
              note: '通ると痕跡',
            ),
            _FacilityTile(
              width: cellW,
              icon: Icons.wifi_off_outlined,
              label: '通信妨害',
              note: '情報を乱す',
            ),
            _FacilityTile(
              width: w,
              icon: Icons.account_balance_outlined,
              label: '告発施設',
              note: '${GuideTerms.trueOni}を当てる',
            ),
          ],
        );
      },
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.note,
  });

  final double width;
  final IconData icon;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(note, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DIA-WEREWOLF-001
class WerewolfNotOniDiagram extends StatelessWidget {
  const WerewolfNotOniDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const werewolfColor = Color(0xFF8E5BD8);
    final oniColor = theme.colorScheme.error;
    return Row(
      children: [
        Expanded(
          child: _RoleBadge(
            color: werewolfColor,
            icon: Icons.psychology_alt_rounded,
            label: GuideTerms.werewolf,
            note: '鬼のように動ける',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('≠', style: theme.textTheme.titleLarge),
        ),
        Expanded(
          child: _RoleBadge(
            color: oniColor,
            icon: Icons.nightlight_round,
            label: GuideTerms.trueOni,
            note: '告発の対象',
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.color,
    required this.icon,
    required this.label,
    required this.note,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// DIA-SKILL-001
class SkillPlacementDiagram extends StatelessWidget {
  const SkillPlacementDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpFlowDiagram(
      steps: [
        (icon: Icons.bolt, label: 'スキル', color: null),
        (icon: Icons.pan_tool_alt_outlined, label: '長押し', color: null),
        (icon: Icons.check_circle_outline, label: '離して設置', color: null),
      ],
    );
  }
}

/// DIA-ROLE-001
class RoleOverviewDiagram extends StatelessWidget {
  const RoleOverviewDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiagramMiniCard(
          icon: Icons.directions_run_rounded,
          iconColor: const Color(0xFF1FA98A),
          title: GuideTerms.humanFaction,
          lines: const [
            GuideTerms.runner,
            'アナリスト',
            'ハッカー',
          ],
        ),
        const SizedBox(height: 8),
        _DiagramMiniCard(
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFFD64545),
          title: GuideTerms.oniFaction,
          lines: [GuideTerms.trueOni],
        ),
        const SizedBox(height: 8),
        _DiagramMiniCard(
          icon: Icons.psychology_alt_rounded,
          iconColor: const Color(0xFF8E5BD8),
          title: '特殊',
          lines: [
            '${GuideTerms.werewolf}（${GuideTerms.trueOni}ではない）',
          ],
        ),
      ],
    );
  }
}

/// スキル章の概要図
class SkillOverviewDiagram extends StatelessWidget {
  const SkillOverviewDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DiagramMiniCard(
          icon: Icons.directions_run_rounded,
          iconColor: const Color(0xFF1FA98A),
          title: GuideTerms.runner,
          lines: const ['偽位置', '捕獲結界'],
        ),
        const SizedBox(height: 8),
        _DiagramMiniCard(
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFFD64545),
          title: GuideTerms.trueOni,
          lines: const ['偽情報暴露', '捕獲結界', '体投げ'],
        ),
        const SizedBox(height: 8),
        _DiagramMiniCard(
          icon: Icons.psychology_alt_rounded,
          iconColor: const Color(0xFF8E5BD8),
          title: GuideTerms.werewolf,
          lines: const ['鬼化'],
        ),
      ],
    );
  }
}
