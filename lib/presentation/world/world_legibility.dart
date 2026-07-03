import 'package:flutter/material.dart';

import '../../theme/map_hud_contrast.dart';
import '../../theme/world_profile.dart';
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

  /// 任意の背景色上で読めるアクセント色。
  Color worldAccentOn(Color background) =>
      worldPresentation.accentOn(background);

  /// フィルドボタン上のラベル色。
  Color get worldButtonLabel => worldPresentation.buttonLabelOnAccent;

  /// 不透明パネル背景。
  Color get worldPanelBg => worldPresentation.panelSurfaceOpaque;

  /// 試合中 HUD の前景色セット。
  MapHudRunningLegibility runningHudLegibility([WorldProfile? profile]) =>
      MapHudRunningLegibility.resolve(
        Theme.of(this).colorScheme,
        profile ?? worldProfile,
      );

  /// 準備画面 HUD の前景色セット。
  MapHudPrepLegibility prepHudLegibility([WorldProfile? profile]) =>
      MapHudPrepLegibility.resolve(
        Theme.of(this).colorScheme,
        profile ?? worldProfile,
      );

  /// 準備中マップパネルの前景色セット。
  MapHudMapPanelLegibility mapPanelLegibility([WorldProfile? profile]) =>
      MapHudMapPanelLegibility.resolve(
        Theme.of(this).colorScheme,
        profile ?? worldProfile,
      );

  /// 図解・CustomPaint 向け色。
  WorldDiagramLegibility diagramLegibility([WorldProfile? profile]) =>
      WorldDiagramLegibility.resolve(profile ?? worldProfile);

  /// 任意の背景色上の本文色（パネル・半透明チップ・バナー等）。
  Color worldTextOn(Color background) =>
      worldPresentation.textOn(background);

  /// 任意の背景色上の補助色。
  Color worldMutedOn(Color background) =>
      worldPresentation.mutedOn(background);
}
