import 'package:flutter/material.dart';

/// 一行 HUD 用。幅に収まらないときだけ新幹線案内のようにゆっくり横スクロール。
class HudMarqueeText extends StatefulWidget {
  const HudMarqueeText({
    required this.text,
    this.style,
    super.key,
  });

  final String text;
  final TextStyle? style;

  @override
  State<HudMarqueeText> createState() => _HudMarqueeTextState();
}

class _HudMarqueeTextState extends State<HudMarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  double _overflow = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncAnimation(double overflow) {
    if (overflow <= 1) {
      if (_controller == null && _overflow <= 1) return;
      _controller?.dispose();
      _controller = null;
      _overflow = 0;
      setState(() {});
      return;
    }
    if ((_overflow - overflow).abs() < 1 && _controller != null) return;
    _overflow = overflow;
    _controller?.dispose();
    // 約 28px/s — 読みやすいが急がない速度
    final seconds = (overflow / 28).clamp(6.0, 28.0);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    )..repeat();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final style = widget.style ?? Theme.of(context).textTheme.bodySmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return Text(text, maxLines: 1, style: style);
        }

        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: double.infinity);

        final textW = painter.size.width;
        if (textW <= maxW + 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncAnimation(0);
          });
          return Text(text, maxLines: 1, style: style);
        }

        final overflow = textW - maxW + 32;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncAnimation(overflow);
        });

        final ctrl = _controller;
        if (ctrl == null) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: style,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              final t = ctrl.value;
              // 端で少し止める（0–8% / 92–100%）
              double offset;
              if (t < 0.08) {
                offset = 0;
              } else if (t > 0.92) {
                offset = overflow;
              } else {
                final u = (t - 0.08) / 0.84;
                offset = overflow * Curves.easeInOut.transform(u);
              }
              return Transform.translate(
                offset: Offset(-offset, 0),
                child: child,
              );
            },
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: style,
            ),
          ),
        );
      },
    );
  }
}
