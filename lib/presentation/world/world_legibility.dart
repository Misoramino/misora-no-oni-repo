import 'package:flutter/material.dart';

import 'world_presentation_context.dart';

/// 世界観トークンへのショートカット（ガイド・チュートリアル・シート向け）。
extension WorldLegibilityOnContext on BuildContext {
  /// パネル／カード上の本文色。
  Color get worldBody => worldPresentation.textOnPanel;

  /// パネル／カード上の補助色。
  Color get worldMuted => worldPresentation.mutedOnPanel;

  /// グラデーション背景上の本文色。
  Color get worldBodyOnScaffold => worldPresentation.textOnScaffold;

  /// グラデーション背景上の補助色。
  Color get worldMutedOnScaffold => worldPresentation.mutedOnScaffold;

  /// 見出し・アクセント（背景に応じて読みやすい色）。
  Color get worldAccentReadable => worldPresentation.accentOnScaffold;

  /// フィルドボタン上のラベル色。
  Color get worldButtonLabel => worldPresentation.buttonLabelOnAccent;

  /// 不透明パネル背景。
  Color get worldPanelBg => worldPresentation.panelSurfaceOpaque;
}
