import 'package:flutter/material.dart';

/// 一行 HUD 用。全文が途切れず流れる（2連複製 + 無限スクロール）。
class HudMarqueeText extends StatefulWidget {
  const HudMarqueeText({
    required this.text,
    this.style,
    this.gap = 40,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final double gap;

  @override
  State<HudMarqueeText> createState() => _HudMarqueeTextState();
}

class _HudMarqueeTextState extends State<HudMarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  double _cycleWidth = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _ensureController(double cycleWidth) {
    if (cycleWidth <= 0) return;
    if (_controller != null && (_cycleWidth - cycleWidth).abs() < 0.5) return;
    _cycleWidth = cycleWidth;
    _controller?.dispose();
    final seconds = (cycleWidth / 30).clamp(8.0, 36.0);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    )..repeat();
  }

  void _stopController() {
    if (_controller == null) return;
    _controller?.dispose();
    _controller = null;
    _cycleWidth = 0;
  }

  @override
  void didUpdateWidget(HudMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _stopController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (text.isEmpty) return const SizedBox.shrink();

    final style = widget.style ?? Theme.of(context).textTheme.bodySmall;
    final textDir = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return Text(text, maxLines: 1, style: style);
        }

        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: textDir,
        )..layout(maxWidth: double.infinity);

        final textW = painter.size.width;
        if (textW <= maxW + 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _stopController();
              setState(() {});
            }
          });
          return Text(text, maxLines: 1, style: style);
        }

        final cycle = textW + widget.gap;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureController(cycle);
          setState(() {});
        });

        final ctrl = _controller;
        if (ctrl == null) {
          return Text(text, maxLines: 1, softWrap: false, style: style);
        }

        Widget segment() => Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: style,
            );

        return ClipRect(
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, _) {
              final offset = -(ctrl.value * cycle);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    segment(),
                    SizedBox(width: widget.gap),
                    segment(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
