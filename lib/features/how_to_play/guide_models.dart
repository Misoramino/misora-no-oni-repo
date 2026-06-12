import 'package:flutter/material.dart';

import 'guide_diagram_type.dart';

/// 作戦マニュアル全体のヘッダー文案。
class GuideHeaderData {
  const GuideHeaderData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.hint,
    required this.indexPrompt,
  });

  final String title;
  final String subtitle;
  final String body;
  final String hint;
  final String indexPrompt;
}

/// 章データ。
class GuideSectionData {
  const GuideSectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.oneLine,
    required this.cards,
    this.sectionDiagram,
    this.details = const [],
    this.relatedSectionIds = const [],
    this.initiallyExpanded = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final String oneLine;
  final List<GuideCardData> cards;
  final GuideDiagramData? sectionDiagram;
  final List<GuideDetailData> details;
  final List<String> relatedSectionIds;
  final bool initiallyExpanded;
}

/// カード1枚分のデータ。
class GuideCardData {
  const GuideCardData({
    required this.id,
    required this.title,
    required this.icon,
    required this.oneLine,
    required this.body,
    this.bullets = const [],
    this.diagram,
    this.details = const [],
    this.footnote,
    this.specRows = const [],
    this.specGroups = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String oneLine;
  final String body;
  final List<String> bullets;
  final GuideDiagramData? diagram;
  final List<GuideDetailData> details;
  final String? footnote;

  /// [id] == spec のカード用。ラベルと値の表形式で表示する。
  final List<GuideSpecRow> specRows;

  /// 見出し付きの表ブロック（第二ゲームなど）。
  final List<GuideSpecGroup> specGroups;
}

/// 詳細ルール表の1行。
class GuideSpecRow {
  const GuideSpecRow(this.label, this.value);

  final String label;
  final String value;
}

/// 詳細ルール表のグループ見出し。
class GuideSpecGroup {
  const GuideSpecGroup({required this.title, required this.rows});

  final String title;
  final List<GuideSpecRow> rows;
}

/// 折りたたみ詳細。
class GuideDetailData {
  const GuideDetailData({
    required this.title,
    required this.body,
    this.specCardId,
  });

  final String title;
  final String body;

  /// 指定時、「詳細ルールで見る」から該当カードへジャンプできる。
  final String? specCardId;
}

/// 図解スロット（Phase B で描画を差し込む）。
class GuideDiagramData {
  const GuideDiagramData({
    required this.type,
    required this.title,
    this.caption,
  });

  final GuideDiagramType type;
  final String title;
  final String? caption;
}
