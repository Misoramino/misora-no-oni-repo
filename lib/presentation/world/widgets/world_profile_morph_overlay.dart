import 'package:flutter/material.dart';

import '../world_presentation_catalog.dart';
import '../../../theme/world_profile.dart';
import 'world_ambient_painter.dart';

/// 世界観切替時に背景・パーティクルを 0.6〜1.0 秒でクロスフェードするオーバーレイ。
class WorldProfileMorphOverlay extends StatefulWidget {
  const WorldProfileMorphOverlay({
    required this.profile,
    this.duration = const Duration(milliseconds: 850),
    super.key,
  });

  final WorldProfile profile;
  final Duration duration;

  @override
  State<WorldProfileMorphOverlay> createState() =>
      _WorldProfileMorphOverlayState();
}

class _WorldProfileMorphOverlayState extends State<WorldProfileMorphOverlay>
    with SingleTickerProviderStateMixin {
  late WorldProfile _from;
  late WorldProfile _to;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _from = widget.profile;
    _to = widget.profile;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(WorldProfileMorphOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile == widget.profile) return;
    _from = oldWidget.profile;
    _to = widget.profile;
    _controller.duration = widget.duration;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          if (t >= 0.999) return const SizedBox.shrink();
          final inv = 1 - t;
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: inv * 0.92,
                child: _MorphLayer(profile: _from, phase: 0),
              ),
              Opacity(
                opacity: t * 0.92,
                child: _MorphLayer(profile: _to, phase: t),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MorphLayer extends StatelessWidget {
  const _MorphLayer({required this.profile, required this.phase});

  final WorldProfile profile;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: pack.scaffoldGradient),
      child: CustomPaint(
        painter: WorldAmbientPainter(
          pack: pack,
          phase: phase,
          strength: 0.55,
        ),
      ),
    );
  }
}
