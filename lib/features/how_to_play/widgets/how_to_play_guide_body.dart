import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  'skills',
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
    this.initialGuideCardId,
    super.key,
  });

  final ScrollController scrollController;
  final PlayerRole? yourRole;

  /// 指定時、初回表示でその章を展開してスクロールする。
  final String? initialSectionId;

  /// 指定時、詳細ルールの該当カードへジャンプする。
  final String? initialSpecCardId;

  /// 指定時、任意の章内カード（スキル章など）へジャンプする。
  final String? initialGuideCardId;

  @override
  State<HowToPlayGuideBody> createState() => _HowToPlayGuideBodyState();
}

class _HowToPlayGuideBodyState extends State<HowToPlayGuideBody> {
  late final Map<String, bool> _expanded;

  final _sectionKeys = <String, GlobalKey>{
    for (final s in howToPlaySections) s.id: GlobalKey(),
  };

  final _cardKeys = <String, GlobalKey>{
    for (final id in guideCardIds) id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _expanded = {
      for (final s in howToPlaySections) s.id: s.initiallyExpanded,
    };
    final guideCard = widget.initialGuideCardId;
    final specCard = widget.initialSpecCardId;
    final jump = widget.initialSectionId;
    if (guideCard != null && _cardKeys.containsKey(guideCard)) {
      final sectionId = guideSectionIdForCard(guideCard);
      if (sectionId != null) {
        _expanded[sectionId] = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openGuideCard(guideCard);
        });
      }
    } else if (specCard != null && _cardKeys.containsKey(specCard)) {
      _expanded['spec'] = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openGuideCard(specCard);
      });
    } else if (jump != null && howToPlaySections.any((s) => s.id == jump)) {
      _expanded[jump] = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSection(jump, scrollOnly: false);
      });
    }
  }

  void _afterLayout(VoidCallback action, {int frames = 2}) {
    void tick(int left) {
      if (!mounted) return;
      if (left <= 0) {
        action();
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) => tick(left - 1));
    }

    tick(frames);
  }

  void _openGuideCard(String cardId) {
    if (!_cardKeys.containsKey(cardId)) return;
    final sectionId = guideSectionIdForCard(cardId) ?? 'spec';
    setState(() => _expanded[sectionId] = true);
    _afterLayout(() {
      _scrollToKey(_sectionKeys[sectionId], attempt: 0, then: () {
        _afterLayout(() {
          _scrollToKey(_cardKeys[cardId], attempt: 0);
        });
      });
    }, frames: 3);
  }

  void _scrollToKey(GlobalKey? key, {required int attempt, VoidCallback? then}) {
    if (attempt > 24 || !mounted) return;
    final ctx = key?.currentContext;
    if (ctx == null) {
      _afterLayout(
        () => _scrollToKey(key, attempt: attempt + 1, then: then),
        frames: 1,
      );
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    ).then((_) => then?.call());
  }

  void _openSection(String id, {bool scrollOnly = false}) {
    if (!scrollOnly) {
      setState(() => _expanded[id] = true);
    }
    _afterLayout(() => _scrollToSection(id, attempt: 0), frames: 2);
  }

  void _scrollToSection(String id, {required int attempt}) {
    if (attempt > 24 || !mounted) return;
    final ctx = _sectionKeys[id]?.currentContext;
    if (ctx == null) {
      _afterLayout(() => _scrollToSection(id, attempt: attempt + 1), frames: 1);
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
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
                    onOpenSpecCard: _openGuideCard,
                    cardKeys: _cardKeys,
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
