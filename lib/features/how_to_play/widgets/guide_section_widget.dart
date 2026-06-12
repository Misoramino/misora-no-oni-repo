import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../game_map/widgets/role_briefing_dialog.dart';
import '../guide_models.dart';
import 'guide_card.dart';
import 'guide_detail_expansion.dart';
import 'guide_diagram_slot.dart';
import 'guide_related_links.dart';

/// 章1つ分の UI（将来の専用画面でも再利用可能）。
class GuideSectionWidget extends StatelessWidget {
  const GuideSectionWidget({
    required this.section,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onRelatedSectionTap,
    this.yourRole,
    super.key,
  });

  final GuideSectionData section;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<String> onRelatedSectionTap;
  final PlayerRole? yourRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('${section.id}-$expanded'),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          leading: Icon(section.icon, color: scheme.primary),
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            section.oneLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (section.sectionDiagram != null)
              GuideDiagramSlot(data: section.sectionDiagram!),
            for (final card in section.cards) GuideCard(data: card),
            if (section.id == 'roles') _RoleBriefingsPanel(yourRole: yourRole),
            if (section.details.isNotEmpty)
              GuideDetailExpansion(details: section.details),
            GuideRelatedLinks(
              relatedSectionIds: section.relatedSectionIds,
              onSectionTap: onRelatedSectionTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBriefingsPanel extends StatelessWidget {
  const _RoleBriefingsPanel({this.yourRole});

  final PlayerRole? yourRole;

  @override
  Widget build(BuildContext context) {
    final otherRoles = PlayerRole.values
        .where((r) => r != yourRole)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          'くわしい操作・スキル',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        if (yourRole != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: roleBriefingBlock(
              context,
              yourRole!,
              emphasized: true,
            ),
          ),
        for (final role in yourRole != null ? otherRoles : PlayerRole.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: roleBriefingBlock(context, role),
          ),
      ],
    );
  }
}
