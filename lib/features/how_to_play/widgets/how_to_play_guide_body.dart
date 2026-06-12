import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../guide_sections.dart';
import 'guide_header_card.dart';
import 'guide_section_index.dart';
import 'guide_section_widget.dart';
import 'guide_your_role_card.dart';

/// 章インデックスに出す優先6項目（全12章は下の一覧）。
const guideIndexSectionIds = [
  'win',
  'info',
  'combat',
  'accusation',
  'roles',
  'spec',
];

/// 作戦マニュアルの本文（ボトムシート・将来の専用画面で共用）。
class HowToPlayGuideBody extends StatefulWidget {
  const HowToPlayGuideBody({
    required this.scrollController,
    this.yourRole,
    this.initialSectionId,
    this.initialSpecCardId,
    super.key,
  });

  final ScrollController scrollController;
  final PlayerRole? yourRole;

  /// 指定時、初回表示でその章を展開してスクロールする。
  final String? initialSectionId;

  /// 指定時、詳細ルールの該当カードへジャンプする。
  final String? initialSpecCardId;

  @override
  State<HowToPlayGuideBody> createState() => _HowToPlayGuideBodyState();
}

class _HowToPlayGuideBodyState extends State<HowToPlayGuideBody> {
  late final Map<String, bool> _expanded;

  final _sectionKeys = <String, GlobalKey>{
    for (final s in howToPlaySections) s.id: GlobalKey(),
  };

  final _cardKeys = <String, GlobalKey>{
    for (final id in guideSpecCardIds) id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _expanded = {
      for (final s in howToPlaySections) s.id: s.initiallyExpanded,
    };
    final jump = widget.initialSectionId;
    if (jump != null && howToPlaySections.any((s) => s.id == jump)) {
      _expanded[jump] = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSection(jump, scrollOnly: false);
      });
    }
    final specCard = widget.initialSpecCardId;
    if (specCard != null && _cardKeys.containsKey(specCard)) {
      _expanded['spec'] = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSpecCard(specCard);
      });
    }
  }

  void _openSpecCard(String cardId) {
    if (!_cardKeys.containsKey(cardId)) return;
    setState(() => _expanded['spec'] = true);
    _scrollToKey(_sectionKeys['spec'], attempt: 0, then: () {
      _scrollToKey(_cardKeys[cardId], attempt: 0);
    });
  }

  void _scrollToKey(GlobalKey? key, {required int attempt, VoidCallback? then}) {
    if (attempt > 10 || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key?.currentContext;
      if (ctx == null) {
        _scrollToKey(key, attempt: attempt + 1, then: then);
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      ).then((_) => then?.call());
    });
  }

  void _openSection(String id, {bool scrollOnly = false}) {
    if (!scrollOnly) {
      setState(() => _expanded[id] = true);
    }
    _scrollToSection(id, attempt: 0);
  }

  void _scrollToSection(String id, {required int attempt}) {
    if (attempt > 8 || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _sectionKeys[id]?.currentContext;
      if (ctx == null) {
        _scrollToSection(id, attempt: attempt + 1);
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final indexSections = [
      for (final id in guideIndexSectionIds)
        if (guideSectionById(id) != null) guideSectionById(id)!,
    ];

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GuideHeaderCard(data: guideHeader),
              if (widget.yourRole != null)
                GuideYourRoleCard(role: widget.yourRole!),
              GuideSectionIndex(
                sections: indexSections,
                prompt: guideHeader.indexPrompt,
                footer: '下に全12章の一覧があります。',
                onSectionTap: _openSection,
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = howToPlaySections[index];
                return KeyedSubtree(
                  key: _sectionKeys[section.id],
                  child: GuideSectionWidget(
                    section: section,
                    expanded: _expanded[section.id] ?? false,
                    onExpansionChanged: (v) =>
                        setState(() => _expanded[section.id] = v),
                    onRelatedSectionTap: _openSection,
                    onOpenSpecCard: _openSpecCard,
                    cardKeys: section.id == 'spec' ? _cardKeys : null,
                    yourRole: widget.yourRole,
                  ),
                );
              },
              childCount: howToPlaySections.length,
            ),
          ),
        ),
      ],
    );
  }
}
