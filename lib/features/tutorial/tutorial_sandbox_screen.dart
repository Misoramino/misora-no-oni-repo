import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../game/player_role.dart';
import '../how_to_play/guide_text.dart';
import '../../widgets/juicy_tap.dart';
import '../game_map/widgets/how_to_play_sheet.dart';
import '../game_map/widgets/role_briefing_dialog.dart';
import 'tutorial_copy.dart';
import 'tutorial_widgets.dart';

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

enum _Act {
  tapNext,
  move,
  flee,
  chase,
  skillInstant,
  skillMapPlace,
}

class _Step {
  const _Step({
    required this.text,
    required this.act,
    this.showOni = false,
    this.showRunner = false,
    this.showAnonMarker = false,
    this.showAccusationMarker = false,
    this.guideSectionId,
  });

  final String text;
  final _Act act;
  final bool showOni;
  final bool showRunner;
  final bool showAnonMarker;
  final bool showAccusationMarker;
  final String? guideSectionId;

  static _Act _actFrom(TutorialStepInteraction i) => switch (i) {
        TutorialStepInteraction.tapNext => _Act.tapNext,
        TutorialStepInteraction.moveArena => _Act.move,
        TutorialStepInteraction.fleeOni => _Act.flee,
        TutorialStepInteraction.chaseRunner => _Act.chase,
        TutorialStepInteraction.skillInstant => _Act.skillInstant,
        TutorialStepInteraction.skillMapPlace => _Act.skillMapPlace,
      };
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
  bool _skillArmed = false;
  bool _werewolfTransformed = false;
  bool _fakePositionActive = false;
  bool _placementHolding = false;
  double _placementHoldSeconds = 0;
  Offset? _placementPreview;
  Offset? _placedZoneCenter;
  bool _finished = false;
  double _lastUiPaintAt = 0;

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
      for (final copy in copies)
        _Step(
          text: copy.text,
          act: _Step._actFrom(copy.interaction),
          showOni: copy.showOni,
          showRunner: copy.showRunner,
          showAnonMarker: copy.showAnonMarker,
          showAccusationMarker: copy.showAccusationMarker,
          guideSectionId: copy.guideSectionId,
        ),
    ];
  }

  void _resetStepSkillState() {
    _skillPressed = false;
    _skillArmed = false;
    _werewolfTransformed = false;
    _fakePositionActive = false;
    _placementHolding = false;
    _placementHoldSeconds = 0;
    _placementPreview = null;
    _placedZoneCenter = null;
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
    var dirty = false;

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
        dirty = true;
      } else {
        _moveTarget = null;
      }
    }

    // ダミーの挙動。
    switch (_step.act) {
      case _Act.flee:
        // 鬼がゆっくり追う。
        final nextOni = _moveToward(_oni, _player, 0.16 * dt);
        if ((nextOni - _oni).distance > 0.0005) {
          _oni = nextOni;
          dirty = true;
        }
      case _Act.chase:
        // 逃走者が逃げる。
        final away = _runner - _player;
        if (away.distance < 0.34) {
          final nextRunner = _clampToArea(
            _moveToward(_runner, _runner + away, 0.22 * dt),
          );
          if ((nextRunner - _runner).distance > 0.0005) {
            _runner = nextRunner;
            dirty = true;
          }
        }
      case _Act.tapNext:
      case _Act.move:
      case _Act.skillInstant:
      case _Act.skillMapPlace:
        if (_placementHolding) {
          _placementHoldSeconds += dt;
          dirty = true;
        }
        break;
    }

    _evaluateCompletion();

    final nowSec = elapsed.inMicroseconds / 1e6;
    final animating = _step.act == _Act.flee || _step.act == _Act.chase;
    if (dirty || animating) {
      if (nowSec - _lastUiPaintAt >= 1 / 60) {
        _lastUiPaintAt = nowSec;
        if (mounted) setState(() {});
      }
    }
  }

  void _evaluateCompletion() {
    if (_stepDone) return;
    final done = switch (_step.act) {
      _Act.tapNext => false,
      _Act.move => _travel >= 0.28 && _stepElapsed >= 1.5,
      _Act.skillInstant => _skillPressed && _stepElapsed >= 0.8,
      _Act.skillMapPlace =>
        _placedZoneCenter != null && _stepElapsed >= 1.0,
      _Act.flee => _travel >= 0.15 && _stepElapsed >= 5.5,
      _Act.chase =>
        (_runner - _player).distance <= 0.07 && _stepElapsed >= 3.5,
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
      _moveTarget = null;
      _resetStepSkillState();
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
      _moveTarget = null;
      _finished = false;
      _resetStepSkillState();
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

  void _onArenaPlaceDown(Offset normalized) {
    if (_finished || _step.act != _Act.skillMapPlace || !_skillArmed) return;
    setState(() {
      _placementHolding = true;
      _placementHoldSeconds = 0;
      _placementPreview = _clampToArea(normalized);
    });
  }

  void _onArenaPlaceMove(Offset normalized) {
    if (!_placementHolding) return;
    setState(() => _placementPreview = _clampToArea(normalized));
  }

  void _onArenaPlaceUp() {
    if (!_placementHolding) return;
    if (_placementHoldSeconds >= 0.35 && _placementPreview != null) {
      setState(() {
        _placedZoneCenter = _placementPreview;
        _placementHolding = false;
        _placementPreview = null;
        _skillArmed = false;
      });
      GameAudio.instance.playSfx(SfxId.skillCast);
      _evaluateCompletion();
    } else {
      setState(() {
        _placementHolding = false;
        _placementPreview = null;
      });
    }
  }

  void _cancelMapPlacement() {
    if (_step.act != _Act.skillMapPlace) return;
    setState(() => _resetStepSkillState());
  }

  void _onSkill() {
    GameAudio.instance.playSfx(SfxId.skillCast);
    switch (_step.act) {
      case _Act.skillInstant:
        setState(() {
          _skillPressed = true;
          if (widget.role == PlayerRole.werewolf) {
            _werewolfTransformed = true;
          }
          if (widget.role == PlayerRole.runner) {
            _fakePositionActive = true;
          }
        });
        _evaluateCompletion();
      case _Act.skillMapPlace:
        if (!_skillArmed) {
          setState(() => _skillArmed = true);
        }
      default:
        break;
    }
  }

  Offset? get _fakePositionDecoy =>
      _fakePositionActive ? _player + const Offset(0.14, -0.08) : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillActive = (_step.act == _Act.skillInstant ||
            _step.act == _Act.skillMapPlace) &&
        !_stepDone;
    final mapPlaceActive = _step.act == _Act.skillMapPlace && !_stepDone;

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
          ? TutorialFinishPanel(
              copy: finishCopy,
              accent: _accent,
              onClose: () => Navigator.of(context).pop(),
              onRetry: _restart,
              onOpenGuide: _openGuideSection,
            )
          : Column(
              children: [
                TutorialInstructionBanner(
                  text: _step.text,
                  accent: _accent,
                  missionLabel: 'ミッション ${_index + 1}/${_steps.length}',
                  done: _stepDone,
                  onOpenGuide: _step.guideSectionId == null
                      ? null
                      : () => _openGuideSection(_step.guideSectionId!),
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
                          child: RepaintBoundary(
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: (e) {
                                      final n = Offset(
                                        e.localPosition.dx / side,
                                        e.localPosition.dy / side,
                                      );
                                      if (mapPlaceActive && _skillArmed) {
                                        _onArenaPlaceDown(n);
                                      } else {
                                        _onArenaTap(n);
                                      }
                                    },
                                    onPointerMove: (e) {
                                      if (!mapPlaceActive || !_placementHolding) {
                                        return;
                                      }
                                      _onArenaPlaceMove(
                                        Offset(
                                          e.localPosition.dx / side,
                                          e.localPosition.dy / side,
                                        ),
                                      );
                                    },
                                    onPointerUp: (_) {
                                      if (mapPlaceActive && _placementHolding) {
                                        _onArenaPlaceUp();
                                      }
                                    },
                                    onPointerCancel: (_) {
                                      if (_placementHolding) {
                                        setState(() {
                                          _placementHolding = false;
                                          _placementPreview = null;
                                        });
                                      }
                                    },
                                    child: CustomPaint(
                                      painter: _ArenaPainter(
                                        player: _player,
                                        oni: _step.showOni ? _oni : null,
                                        runner:
                                            _step.showRunner ? _runner : null,
                                        moveTarget: _moveTarget,
                                        showAnonMarker: _step.showAnonMarker,
                                        showAccusationMarker:
                                            _step.showAccusationMarker,
                                        areaCenter: _areaCenter,
                                        areaRadius: _areaRadius,
                                        accent: _accent,
                                        skillPulse: skillActive && !_skillArmed,
                                        werewolfTransformed:
                                            _werewolfTransformed,
                                        fakePositionDecoy: _fakePositionDecoy,
                                        placementPreview: _placementPreview,
                                        placedZone: _placedZoneCenter,
                                        placementHolding: _placementHolding &&
                                            _placementHoldSeconds >= 0.35,
                                        scheme: theme.colorScheme,
                                      ),
                                    ),
                                  ),
                                  if (mapPlaceActive && _skillArmed)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: theme.colorScheme.surface
                                            .withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(20),
                                        child: IconButton(
                                          tooltip: 'キャンセル',
                                          icon: const Icon(Icons.close),
                                          onPressed: _cancelMapPlacement,
                                        ),
                                      ),
                                    ),
                                ],
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
                  skillArmed: _skillArmed,
                  mapPlaceStep: mapPlaceActive,
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

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.role,
    required this.skillLabel,
    required this.skillActive,
    required this.skillArmed,
    required this.mapPlaceStep,
    required this.showNext,
    required this.onSkill,
    required this.onNext,
    required this.accent,
  });

  final PlayerRole role;
  final String skillLabel;
  final bool skillActive;
  final bool skillArmed;
  final bool mapPlaceStep;
  final bool showNext;
  final VoidCallback onSkill;
  final VoidCallback onNext;
  final Color accent;

  String? get _hint {
    if (!skillActive) return null;
    if (mapPlaceStep) {
      return skillArmed
          ? '地図を長押しして離す（×でキャンセル）'
          : 'まずスキルボタンを押してください';
    }
    return switch (role) {
      PlayerRole.runner => 'ボタンで、見える位置をずらします',
      PlayerRole.werewolf => 'ボタンで鬼化の見た目を試します',
      _ => 'ボタンを押して発動',
    };
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                GuideText.forDisplay(hint),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: accent,
                      height: 1.35,
                    ),
              ),
            ),
          Row(
            children: [
              _PulsingWrap(
                active: skillActive,
                color: accent,
                child: JuicyTap(
                  onTap: skillActive ? onSkill : null,
                  sfx: SfxId.skillCast,
                  child: IgnorePointer(
                    child: FilledButton.tonalIcon(
                      onPressed: skillActive ? () {} : null,
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
        ],
      ),
    );
  }
}

class _PulsingWrap extends StatelessWidget {
  const _PulsingWrap({
    required this.active,
    required this.color,
    required this.child,
  });

  final bool active;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
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
    required this.werewolfTransformed,
    required this.fakePositionDecoy,
    required this.placementPreview,
    required this.placedZone,
    required this.placementHolding,
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
  final bool werewolfTransformed;
  final Offset? fakePositionDecoy;
  final Offset? placementPreview;
  final Offset? placedZone;
  final bool placementHolding;
  final ColorScheme scheme;

  static const _zoneRadiusNorm = 0.14;

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

    void drawZone(Offset centerNorm, {required bool preview}) {
      final c = _px(centerNorm, size);
      final r = _zoneRadiusNorm * size.width;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFE53935)
              .withValues(alpha: preview ? 0.12 : 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFE53935)
              .withValues(alpha: preview ? 0.55 : 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = preview ? 2 : 2.5,
      );
    }

    final placed = placedZone;
    if (placed != null) drawZone(placed, preview: false);
    if (placementHolding && placementPreview != null) {
      drawZone(placementPreview!, preview: true);
    }

    // 鬼。
    final o = oni;
    if (o != null) _dot(canvas, _px(o, size), const Color(0xFFD64545), '鬼');

    // 逃走者（ダミー）。
    final r = runner;
    if (r != null) _dot(canvas, _px(r, size), const Color(0xFF2E86DE), '逃');

    // 自分。
    final pp = _px(player, size);
    final decoy = fakePositionDecoy;
    if (decoy != null) {
      final dp = _px(decoy, size);
      canvas.drawCircle(
        dp,
        16,
        Paint()
          ..color = accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        dp,
        16,
        Paint()
          ..color = accent.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _dot(canvas, dp, accent.withValues(alpha: 0.75), '偽', big: false);
      canvas.drawLine(
        pp,
        dp,
        Paint()
          ..color = accent.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
    }
    if (skillPulse) {
      canvas.drawCircle(
        pp,
        22,
        Paint()..color = accent.withValues(alpha: 0.25),
      );
    }
    final selfColor = werewolfTransformed
        ? const Color(0xFFD64545)
        : accent;
    final selfLabel = werewolfTransformed ? '鬼化' : 'You';
    _dot(canvas, pp, selfColor, selfLabel, big: true);
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
      old.skillPulse != skillPulse ||
      old.werewolfTransformed != werewolfTransformed ||
      old.fakePositionDecoy != fakePositionDecoy ||
      old.placementPreview != placementPreview ||
      old.placedZone != placedZone ||
      old.placementHolding != placementHolding;
}
