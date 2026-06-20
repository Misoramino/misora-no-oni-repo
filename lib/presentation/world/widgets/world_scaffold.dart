import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../world_presentation_catalog.dart';
import 'world_ambient_painter.dart';
import 'world_profile_morph_overlay.dart';

/// 世界観グラデーション背景＋薄いアンビエント装飾。
class WorldScaffold extends StatelessWidget {
  const WorldScaffold({
    required this.profile,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.ambientPhase = 0,
    this.showProfileMorph = false,
    this.playEntryReveal = false,
    super.key,
  });

  final WorldProfile profile;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final double ambientPhase;

  /// 世界観切替時のクロスフェード（[WorldAudioDirector.onProfileChanged] と同期利用）。
  final bool showProfileMorph;

  /// 画面入場時の短い世界観リビール。
  final bool playEntryReveal;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: pack.scaffoldBottom,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: pack.scaffoldGradient),
          ),
          if (!MediaQuery.disableAnimationsOf(context))
            CustomPaint(
              painter: WorldAmbientPainter(
                pack: pack,
                phase: ambientPhase,
              ),
            ),
          if (showProfileMorph)
            WorldProfileMorphOverlay(profile: profile),
          body,
          if (playEntryReveal) WorldEntryRevealOverlay(profile: profile),
        ],
      ),
    );
  }
}

/// シート内コンテンツ用の世界観パネル背景。
class WorldPanel extends StatelessWidget {
  const WorldPanel({
    required this.profile,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final WorldProfile profile;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pack.panelSurfaceOpaque,
        borderRadius: BorderRadius.circular(pack.hudCornerRadius + 4),
        border: Border.all(color: pack.panelBorder, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
