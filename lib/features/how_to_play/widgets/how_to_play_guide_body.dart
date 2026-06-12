import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../guide_sections.dart';
import 'guide_header_card.dart';
import 'guide_section_index.dart';
import 'guide_section_widget.dart';

/// 作戦マニュアルの本文（ボトムシート・将来の専用画面で共用）。
class HowToPlayGuideBody extends StatefulWidget {
  const HowToPlayGuideBody({
    required this.scrollController,
    this.yourRole,
    this.initialSectionId,
    super.key,
  });

  final ScrollController scrollController;
  final PlayerRole? yourRole;

  /// 指定時、初回表示でその章を展開してスクロールする。
  final String? initialSectionId;

  @override
  State<HowToPlayGuideBody> createState() => _HowToPlayGuideBodyState();
}

class _HowToPlayGuideBodyState extends State<HowToPlayGuideBody> {
  late final Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = {
      for (final s in howToPlaySections) s.id: s.initiallyExpanded,
    };
    final jump = widget.initialSectionId;
    if (jump != null && howToPlaySections.any((s) => s.id == jump)) {
      _expanded[jump] = true;
      // ボトムシート初回レイアウト後にスクロールするため2フレーム待つ。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openSection(jump));
      });
    }
  }

  void _openSection(String id) {
    setState(() => _expanded[id] = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });
  }

  final _sectionKeys = <String, GlobalKey>{
    for (final s in howToPlaySections) s.id: GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GuideHeaderCard(data: guideHeader),
        GuideSectionIndex(
          sections: howToPlaySections,
          prompt: guideHeader.indexPrompt,
          onSectionTap: _openSection,
        ),
        for (final section in howToPlaySections)
          KeyedSubtree(
            key: _sectionKeys[section.id],
            child: GuideSectionWidget(
              section: section,
              expanded: _expanded[section.id] ?? false,
              onExpansionChanged: (v) =>
                  setState(() => _expanded[section.id] = v),
              onRelatedSectionTap: _openSection,
              yourRole: widget.yourRole,
            ),
          ),
      ],
    );
  }
}
