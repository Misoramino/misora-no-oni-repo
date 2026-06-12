import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../game/player_role.dart';
import '../../widgets/juicy_tap.dart';
import '../game_map/widgets/how_to_play_sheet.dart';
import '../game_map/widgets/role_briefing_dialog.dart';
import 'tutorial_copy.dart';

/// GPS・通信に依存しない、役職別のスクリプト型チュートリアル。
///
/// 簡易アリーナ（タップで移動）とダミーの鬼／逃走者で、
/// 指示に従ってボタンを押しながら基本を体験する。
class TutorialSandboxScreen extends StatefulWidget {
  const TutorialSandboxScreen({required this.role, super.key});

  final PlayerRole role;

  @override
  State<TutorialSandboxScreen> createState() => _TutorialSandboxScreenState();
}

enum _Act { tapNext, move, pressSkill, flee, chase }

class _Step {
  const _Step({
    required this.text,
    required this.act,
    this.showOni = false,
    this.showRunner = false,
    this.showAnonMarker = false,
    this.showAccusationMarker = false,
  });

  final String text;
  final _Act act;
  final bool showOni;
  final bool showRunner;
  final bool showAnonMarker;
  final bool showAccusationMarker;
}

class _TutorialSandboxScreenState extends State<TutorialSandboxScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  // 0..1 のアリーナ座標。
  Offset _player = const Offset(0.5, 0.62);
  Offset _oni = const Offset(0.5, 0.15);
  Offset _runner = const Offset(0.78, 0.3);
  Offset? _moveTarget;
  static const _areaCenter = Offset(0.5, 0.5);
  static const _areaRadius = 0.42;

  late final List<_Step> _steps = _buildSteps(widget.role);
  int _index = 0;
  bool _stepDone = false;
  double _stepElapsed = 0;
  double _travel = 0;
  bool _skillPressed = false;
  bool _finished = false;

  Color get _accent => roleAccentColor(widget.role);
  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _lastTick = Duration.zero;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static List<_Step> _buildSteps(PlayerRole role) {
    final copies = TutorialCopyCatalog.stepsFor(role);
    return [
      for (var i = 0; i < copies.length; i++)
        _Step(
          text: copies[i].text,
          act: _actFor(role, i),
          showOni: copies[i].showOni,
          showRunner: copies[i].showRunner,
          showAnonMarker: copies[i].showAnonMarker,
          showAccusationMarker: copies[i].showAccusationMarker,
        ),
    ];
  }

  static _Act _actFor(PlayerRole role, int index) {
    switch (role) {
      case PlayerRole.runner:
        return switch (index) {
          0 => _Act.move,
          2 => _Act.flee,
          3 => _Act.move,
          _ => _Act.tapNext,
        };
      case PlayerRole.hunter:
        return index == 4 ? _Act.chase : _Act.tapNext;
      case PlayerRole.werewolf:
        return switch (index) {
          1 => _Act.move,
          2 => _Act.pressSkill,
          _ => _Act.tapNext,
        };
    }
  }

  String get _skillLabel => switch (widget.role) {
        PlayerRole.runner => '偽位置',
        PlayerRole.hunter => '捕獲結界',
        PlayerRole.werewolf => '鬼化',
      };

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (_finished) return;

    _stepElapsed += dt;

    // プレイヤー移動（タップ目標へ）。
    final target = _moveTarget;
    if (target != null) {
      final delta = target - _player;
      final dist = delta.distance;
      const speed = 0.42; // 1秒あたりの割合
      if (dist > 0.005) {
        final step = math.min(dist, speed * dt);
        final next = _player + delta / dist * step;
        _travel += step;
        _player = _clampToArea(next);
      } else {
        _moveTarget = null;
      }
    }

    // ダミーの挙動。
    switch (_step.act) {
      case _Act.flee:
        // 鬼がゆっくり追う。
        _oni = _moveToward(_oni, _player, 0.16 * dt);
      case _Act.chase:
        // 逃走者が逃げる。
        final away = _runner - _player;
        if (away.distance < 0.34) {
          _runner = _clampToArea(
            _moveToward(_runner, _runner + away, 0.22 * dt),
          );
        }
      case _Act.tapNext:
      case _Act.move:
      case _Act.pressSkill:
        break;
    }

    _evaluateCompletion();
    if (mounted) setState(() {});
  }

  void _evaluateCompletion() {
    if (_stepDone) return;
    final done = switch (_step.act) {
      _Act.tapNext => false, // ボタンで進む
      _Act.move => _travel >= 0.18,
      _Act.pressSkill => _skillPressed,
      _Act.flee => _stepElapsed >= 4.5,
      _Act.chase => (_runner - _player).distance <= 0.09,
    };
    if (done) _completeStep();
  }

  void _completeStep() {
    if (_stepDone) return;
    _stepDone = true;
    GameAudio.instance.playSfx(SfxId.reward);
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (mounted) _advance();
    });
  }

  void _advance() {
    if (_index >= _steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _stepDone = false;
      _stepElapsed = 0;
      _travel = 0;
      _skillPressed = false;
      _moveTarget = null;
    });
  }

  void _finish() {
    if (_finished) return;
    setState(() => _finished = true);
    GameAudio.instance.playSfx(SfxId.matchWin);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _stepDone = false;
      _stepElapsed = 0;
      _travel = 0;
      _skillPressed = false;
      _moveTarget = null;
      _finished = false;
      _player = const Offset(0.5, 0.62);
      _oni = const Offset(0.5, 0.15);
      _runner = const Offset(0.78, 0.3);
    });
  }

  void _openGuideSection(String sectionId) {
    showHowToPlaySheet(
      context,
      yourRole: widget.role,
      initialSectionId: sectionId,
    );
  }

  Offset _moveToward(Offset from, Offset to, double maxStep) {
    final delta = to - from;
    final dist = delta.distance;
    if (dist <= 0.0001) return from;
    final step = math.min(dist, maxStep);
    return from + delta / dist * step;
  }

  Offset _clampToArea(Offset p) {
    final delta = p - _areaCenter;
    if (delta.distance <= _areaRadius) return p;
    return _areaCenter + delta / delta.distance * _areaRadius;
  }

  void _onArenaTap(Offset normalized) {
    if (_finished) return;
    final act = _step.act;
    if (act == _Act.move || act == _Act.flee || act == _Act.chase) {
      setState(() => _moveTarget = _clampToArea(normalized));
      GameAudio.instance.playSfx(SfxId.uiTap);
    }
  }

  void _onSkill() {
    GameAudio.instance.playSfx(SfxId.skillCast);
    setState(() => _skillPressed = true);
    if (_step.act == _Act.pressSkill) _evaluateCompletion();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillActive = _step.act == _Act.pressSkill && !_stepDone;

    final finishCopy = TutorialCopyCatalog.finishFor(widget.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'チュートリアル — ${TutorialCopyCatalog.roleTutorialTitle(widget.role)}',
        ),
        actions: [
          if (!_finished)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('終了'),
            ),
        ],
      ),
      body: _finished
          ? _TutorialFinishPanel(
              copy: finishCopy,
              accent: _accent,
              onClose: () => Navigator.of(context).pop(),
              onRetry: _restart,
              onOpenGuide: _openGuideSection,
            )
          : Column(
              children: [
                _InstructionBanner(
                  text: _step.text,
                  accent: _accent,
                  step: _index + 1,
                  total: _steps.length,
                  done: _stepDone,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return Center(
                          child: SizedBox(
                            width: side,
                            height: side,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (d) => _onArenaTap(
                                Offset(
                                  d.localPosition.dx / side,
                                  d.localPosition.dy / side,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _ArenaPainter(
                                  player: _player,
                                  oni: _step.showOni ? _oni : null,
                                  runner: _step.showRunner ? _runner : null,
                                  moveTarget: _moveTarget,
                                  showAnonMarker: _step.showAnonMarker,
                                  showAccusationMarker:
                                      _step.showAccusationMarker,
                                  areaCenter: _areaCenter,
                                  areaRadius: _areaRadius,
                                  accent: _accent,
                                  skillPulse: skillActive,
                                  scheme: theme.colorScheme,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _ControlBar(
                  role: widget.role,
                  skillLabel: _skillLabel,
                  skillActive: skillActive,
                  showNext: _step.act == _Act.tapNext,
                  onSkill: _onSkill,
                  onNext: _advance,
                  accent: _accent,
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({
    required this.text,
    required this.accent,
    required this.step,
    required this.total,
    required this.done,
  });

  final String text;
  final Color accent;
  final int step;
  final int total;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      color: accent.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.school_rounded,
            color: done ? Colors.green.shade600 : accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ミッション $step/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.role,
    required this.skillLabel,
    required this.skillActive,
    required this.showNext,
    required this.onSkill,
    required this.onNext,
    required this.accent,
  });

  final PlayerRole role;
  final String skillLabel;
  final bool skillActive;
  final bool showNext;
  final VoidCallback onSkill;
  final VoidCallback onNext;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _PulsingWrap(
            active: skillActive,
            color: accent,
            child: JuicyTap(
              onTap: onSkill,
              sfx: SfxId.skillCast,
              child: IgnorePointer(
                child: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: Icon(roleIcon(role)),
                  label: Text(skillLabel),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (showNext)
            JuicyTap(
              onTap: onNext,
              sfx: SfxId.uiTap,
              child: IgnorePointer(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () {},
                  child: const Text('次へ'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingWrap extends StatefulWidget {
  const _PulsingWrap({
    required this.active,
    required this.color,
    required this.child,
  });

  final bool active;
  final Color color;
  final Widget child;

  @override
  State<_PulsingWrap> createState() => _PulsingWrapState();
}

class _PulsingWrapState extends State<_PulsingWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 + _c.value * 0.4),
                blurRadius: 8 + _c.value * 14,
                spreadRadius: _c.value * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _TutorialFinishPanel extends StatelessWidget {
  const _TutorialFinishPanel({
    required this.copy,
    required this.accent,
    required this.onClose,
    required this.onRetry,
    required this.onOpenGuide,
  });

  final TutorialFinishCopy copy;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final void Function(String sectionId) onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 48, color: accent),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              copy.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 20),
            Text('もっと詳しく見る', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in copy.relatedGuides)
                  ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(g.title),
                    onPressed: () => onOpenGuide(g.sectionId),
                  ),
              ],
            ),
            const Spacer(),
            JuicyTap(
              onTap: onClose,
              sfx: SfxId.uiConfirm,
              child: IgnorePointer(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('とじる'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('もう一度'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.player,
    required this.oni,
    required this.runner,
    required this.moveTarget,
    required this.showAnonMarker,
    required this.showAccusationMarker,
    required this.areaCenter,
    required this.areaRadius,
    required this.accent,
    required this.skillPulse,
    required this.scheme,
  });

  final Offset player;
  final Offset? oni;
  final Offset? runner;
  final Offset? moveTarget;
  final bool showAnonMarker;
  final bool showAccusationMarker;
  final Offset areaCenter;
  final double areaRadius;
  final Color accent;
  final bool skillPulse;
  final ColorScheme scheme;

  static const _anonMarkerPos = Offset(0.36, 0.38);
  static const _accusationMarkerPos = Offset(0.68, 0.52);

  Offset _px(Offset n, Size s) => Offset(n.dx * s.width, n.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = scheme.surfaceContainerHighest;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      bg,
    );

    // プレイエリア（円）。
    final areaC = _px(areaCenter, size);
    final areaR = areaRadius * size.width;
    canvas.drawCircle(
      areaC,
      areaR,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      areaC,
      areaR,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 移動目標。
    final mt = moveTarget;
    if (mt != null) {
      final p = _px(mt, size);
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = accent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (showAnonMarker) {
      _marker(
        canvas,
        _px(_anonMarkerPos, size),
        scheme.tertiary,
        '?',
        label: '匿名',
      );
    }

    if (showAccusationMarker) {
      _facilityMarker(canvas, _px(_accusationMarkerPos, size), scheme.primary);
    }

    // 鬼。
    final o = oni;
    if (o != null) _dot(canvas, _px(o, size), const Color(0xFFD64545), '鬼');

    // 逃走者（ダミー）。
    final r = runner;
    if (r != null) _dot(canvas, _px(r, size), const Color(0xFF2E86DE), '逃');

    // 自分。
    final pp = _px(player, size);
    if (skillPulse) {
      canvas.drawCircle(
        pp,
        22,
        Paint()..color = accent.withValues(alpha: 0.25),
      );
    }
    _dot(canvas, pp, accent, 'You', big: true);
  }

  void _marker(
    Canvas canvas,
    Offset c,
    Color color,
    String glyph, {
    String? label,
  }) {
    canvas.drawCircle(c, 14, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(
      c,
      14,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    if (label != null) {
      final lp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(c.dx - lp.width / 2, c.dy + 16));
    }
  }

  void _facilityMarker(Canvas canvas, Offset c, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 28, height: 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = color.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '告',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    final lp = TextPainter(
      text: const TextSpan(
        text: '告発施設',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lp.paint(canvas, Offset(c.dx - lp.width / 2, c.dy + 18));
  }

  void _dot(Canvas canvas, Offset c, Color color, String label,
      {bool big = false}) {
    final r = big ? 14.0 : 11.0;
    canvas.drawCircle(c, r + 3, Paint()..color = Colors.white);
    canvas.drawCircle(c, r, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: big ? 11 : 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArenaPainter old) =>
      old.player != player ||
      old.oni != oni ||
      old.runner != runner ||
      old.moveTarget != moveTarget ||
      old.showAnonMarker != showAnonMarker ||
      old.showAccusationMarker != showAccusationMarker ||
      old.skillPulse != skillPulse;
}
