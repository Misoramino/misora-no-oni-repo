import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';

/// 準備パネル ↔ マップ表示のフェーズ切替（拡大フェード）。
class PrepMapPhaseShell extends StatelessWidget {
  const PrepMapPhaseShell({
    required this.showMap,
    required this.profile,
    required this.prepChild,
    required this.mapChild,
    super.key,
  });

  final bool showMap;
  final WorldProfile profile;
  final Widget prepChild;
  final Widget mapChild;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce
        ? Duration.zero
        : const Duration(milliseconds: 380);

  return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final inMap = child.key == const ValueKey<String>('prep_map');
        final curved = CurvedAnimation(
          parent: animation,
          curve: inMap ? Curves.easeOutCubic : Curves.easeInCubic,
        );
        final beginScale = switch (profile) {
          WorldProfile.sport => inMap ? 0.88 : 1.0,
          WorldProfile.sciFi => inMap ? 0.94 : 1.0,
          _ => inMap ? 0.92 : 1.0,
        };
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: beginScale, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, inMap ? 0.04 : -0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: showMap
          ? KeyedSubtree(
              key: const ValueKey<String>('prep_map'),
              child: mapChild,
            )
          : KeyedSubtree(
              key: const ValueKey<String>('prep_panel'),
              child: prepChild,
            ),
    );
  }
}
