import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../game/player_role.dart';
import '../../widgets/juicy_tap.dart';
import '../game_map/widgets/role_briefing_dialog.dart';

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
  });

  final String text;
  final _Act act;
  final bool showOni;
  final bool showRunner;
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
    switch (role) {
      case PlayerRole.runner:
        return const [
          _Step(
            text: 'あなたは逃走者。制限時間まで逃げ切れば勝ち！',
            act: _Act.tapNext,
          ),
          _Step(
            text: 'マップをタップして動いてみよう。',
            act: _Act.move,
          ),
          _Step(
            text: '黄色い円の中にいよう。外に出ると位置がバレやすい。',
            act: _Act.tapNext,
          ),
          _Step(
            text: '赤い鬼が来た！タップで動いて距離をとろう。',
            act: _Act.flee,
            showOni: true,
          ),
          _Step(
            text: 'ピンチのときはスキルで揺さぶる。スキルを押してみよう。',
            act: _Act.pressSkill,
            showOni: true,
          ),
          _Step(
            text: 'これで基本はOK！あとは実戦で逃げ切ろう。',
            act: _Act.tapNext,
            showOni: true,
          ),
        ];
      case PlayerRole.hunter:
        return const [
          _Step(
            text: 'あなたは鬼。逃走者に近づいて捕まえれば勝ち！',
            act: _Act.tapNext,
          ),
          _Step(
            text: 'マップをタップして動いてみよう。',
            act: _Act.move,
          ),
          _Step(
            text: '青い逃走者を追いかけて、ぐっと近づこう。',
            act: _Act.chase,
            showRunner: true,
          ),
          _Step(
            text: 'スキルで逃げ場を奪える。スキルを押してみよう。',
            act: _Act.pressSkill,
            showRunner: true,
          ),
          _Step(
            text: '捕獲成功！この調子で逃走者を狩ろう。',
            act: _Act.tapNext,
            showRunner: true,
          ),
        ];
      case PlayerRole.werewolf:
        return const [
          _Step(
            text: 'あなたは人狼。人と鬼の「少ない方」の味方だ。',
            act: _Act.tapNext,
          ),
          _Step(
            text: '正体を隠して立ち回るのが鍵。まずは動いてみよう。',
            act: _Act.move,
          ),
          _Step(
            text: '状況に応じて鬼の力を使える。変身スキルを押してみよう。',
            act: _Act.pressSkill,
          ),
          _Step(
            text: '人のふりをして近づき、隙をつくのが人狼の強み。',
            act: _Act.tapNext,
          ),
          _Step(
            text: '準備OK！陣営の人数を見ながら立ち回ろう。',
            act: _Act.tapNext,
          ),
        ];
    }
  }

  String get _skillLabel => switch (widget.role) {
        PlayerRole.runner => '偽情報',
        PlayerRole.hunter => '捕縛ゾーン',
        PlayerRole.werewolf => '変身',
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

    return Scaffold(
      appBar: AppBar(
        title: Text('チュートリアル — ${widget.role.displayName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('終了'),
          ),
        ],
      ),
      body: Column(
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
            showNext: _step.act == _Act.tapNext && !_finished,
            onSkill: _onSkill,
            onNext: _advance,
            accent: _accent,
          ),
          if (_finished)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: JuicyTap(
                onTap: () => Navigator.of(context).pop(),
                sfx: SfxId.uiConfirm,
                child: IgnorePointer(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('クリア！とじる'),
                  ),
                ),
              ),
            ),
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
            '$step/$total',
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

class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.player,
    required this.oni,
    required this.runner,
    required this.moveTarget,
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
  final Offset areaCenter;
  final double areaRadius;
  final Color accent;
  final bool skillPulse;
  final ColorScheme scheme;

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
      old.skillPulse != skillPulse;
}
