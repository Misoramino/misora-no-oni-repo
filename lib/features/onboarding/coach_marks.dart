import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';

/// コーチマーク1ステップ。対象が見つからなければ中央にカードを出す。
class CoachStep {
  const CoachStep({
    required this.title,
    required this.body,
    this.icon = Icons.touch_app_rounded,
    this.targetKey,
  });

  final String title;
  final String body;
  final IconData icon;
  final GlobalKey? targetKey;
}

/// 初回ガイド用の軽量コーチマーク。要素をスポットライトで囲んで説明する。
/// タップで次へ進み、最後に閉じる。
Future<void> showCoachMarks(BuildContext context, List<CoachStep> steps) {
  if (steps.isEmpty) return Future<void>.value();
  GameAudio.instance.playSfx(SfxId.uiConfirm);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondary) =>
          _CoachMarksOverlay(steps: steps),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _CoachMarksOverlay extends StatefulWidget {
  const _CoachMarksOverlay({required this.steps});

  final List<CoachStep> steps;

  @override
  State<_CoachMarksOverlay> createState() => _CoachMarksOverlayState();
}

class _CoachMarksOverlayState extends State<_CoachMarksOverlay> {
  int _index = 0;

  Rect? _targetRect(CoachStep step) {
    final ctx = step.targetKey?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  void _advance() {
    if (_index >= widget.steps.length - 1) {
      GameAudio.instance.playSfx(SfxId.uiConfirm);
      Navigator.of(context).pop();
      return;
    }
    GameAudio.instance.playSfx(SfxId.uiTap);
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final size = MediaQuery.of(context).size;
    final rawRect = _targetRect(step);
    final rect = rawRect == null
        ? null
        : Rect.fromLTRB(
            rawRect.left - 8,
            rawRect.top - 8,
            rawRect.right + 8,
            rawRect.bottom + 8,
          );
    final isLast = _index == widget.steps.length - 1;

    // カードは対象の上 or 下の広い方へ。対象が無ければ中央。
    final showBelow = rect != null && rect.center.dy < size.height * 0.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SpotlightPainter(rect)),
          ),
          if (rect != null)
            Positioned(
              left: rect.left,
              top: rect.top,
              child: IgnorePointer(
                child: Container(
                  width: rect.width,
                  height: rect.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          _positionedCard(context, rect, showBelow, size, step, isLast),
        ],
      ),
    );
  }

  Widget _positionedCard(
    BuildContext context,
    Rect? rect,
    bool showBelow,
    Size size,
    CoachStep step,
    bool isLast,
  ) {
    final card = _CoachCard(
      step: step,
      index: _index,
      total: widget.steps.length,
      isLast: isLast,
    );
    if (rect == null) {
      return Center(child: card);
    }
    final top = showBelow ? rect.bottom + 16 : null;
    final bottom = showBelow ? null : size.height - rect.top + 16;
    return Positioned(
      left: 20,
      right: 20,
      top: top,
      bottom: bottom,
      child: Align(
        alignment: showBelow ? Alignment.topCenter : Alignment.bottomCenter,
        child: card,
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final path = Path()
      ..addRect(full)
      ..addRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(14)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => oldDelegate.hole != hole;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
  });

  final CoachStep step;
  final int index;
  final int total;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(step.icon, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}/$total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(step.body, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              // タップ判定は全面の GestureDetector が処理するため見た目専用。
              IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(isLast ? 'はじめる' : '次へ'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
