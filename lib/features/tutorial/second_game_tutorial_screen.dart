import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../widgets/juicy_tap.dart';
import '../game_map/widgets/how_to_play_sheet.dart';
import 'second_game_tutorial_kind.dart';
import 'tutorial_copy.dart';
import 'tutorial_widgets.dart';

Color secondGameTutorialAccent(SecondGameTutorialKind kind) => switch (kind) {
      SecondGameTutorialKind.echoForm => const Color(0xFF6B9BD1),
      SecondGameTutorialKind.vengefulShadow => const Color(0xFF6B4E9C),
    };

IconData secondGameTutorialIcon(SecondGameTutorialKind kind) => switch (kind) {
      SecondGameTutorialKind.echoForm => Icons.graphic_eq_rounded,
      SecondGameTutorialKind.vengefulShadow => Icons.nights_stay_rounded,
    };

/// 脱落後（第二ゲーム）の疑似チュートリアル。本番ロジックは使わない。
class SecondGameTutorialScreen extends StatefulWidget {
  const SecondGameTutorialScreen({required this.kind, super.key});

  final SecondGameTutorialKind kind;

  @override
  State<SecondGameTutorialScreen> createState() => _SecondGameTutorialScreenState();
}

enum _Act { tapNext, chargeAtMarker }

enum _Marker { terminal, accusationFacility, camera }

class _Step {
  const _Step({
    required this.copy,
    required this.act,
    this.marker,
    this.actionLabel,
  });

  final SecondGameTutorialStepCopy copy;
  final _Act act;
  final _Marker? marker;
  final String? actionLabel;
}

class _SecondGameTutorialScreenState extends State<SecondGameTutorialScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _lastUiPaintAt = 0;

  static const _areaCenter = Offset(0.5, 0.5);
  static const _areaRadius = 0.42;
  static const _markerReach = 0.14;
  static const _chargeSeconds = 1.8;

  static const _terminalPos = Offset(0.34, 0.36);
  static const _accusationPos = Offset(0.70, 0.50);
  static const _cameraPos = Offset(0.52, 0.28);

  late final List<_Step> _steps = _buildSteps(widget.kind);
  int _index = 0;
  bool _stepDone = false;
  bool _finished = false;
  bool _charging = false;
  double _chargeProgress = 0;
  String? _flashMessage;
  bool _oniRevealed = false;

  Offset _player = const Offset(0.5, 0.64);
  Offset? _moveTarget;

  Color get _accent => secondGameTutorialAccent(widget.kind);
  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static List<_Step> _buildSteps(SecondGameTutorialKind kind) {
    final copies = TutorialCopyCatalog.stepsForSecondGame(kind);
    return [
      for (var i = 0; i < copies.length; i++)
        _Step(
          copy: copies[i],
          act: i == 0 ? _Act.tapNext : _Act.chargeAtMarker,
          marker: switch (kind) {
            SecondGameTutorialKind.echoForm => switch (i) {
                1 => _Marker.terminal,
                2 => _Marker.accusationFacility,
                _ => null,
              },
            SecondGameTutorialKind.vengefulShadow => switch (i) {
                1 => _Marker.accusationFacility,
                2 => _Marker.camera,
                _ => null,
              },
          },
          actionLabel: switch (kind) {
            SecondGameTutorialKind.echoForm => switch (i) {
                1 => 'ジャック',
                2 => '陣取る',
                _ => null,
              },
            SecondGameTutorialKind.vengefulShadow => switch (i) {
                1 => '妨害',
                2 => '停止',
                _ => null,
              },
          },
        ),
    ];
  }

  Offset? _markerPosition(_Marker marker) => switch (marker) {
        _Marker.terminal => _terminalPos,
        _Marker.accusationFacility => _accusationPos,
        _Marker.camera => _cameraPos,
      };

  bool get _inMarkerRange {
    final marker = _step.marker;
    if (marker == null) return false;
    final pos = _markerPosition(marker)!;
    return (_player - pos).distance <= _markerReach;
  }

  String? get _missionLabel {
    if (_index == 0) return null;
    return 'ミッション $_index/2';
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (_finished) return;

    var dirty = false;

    final target = _moveTarget;
    if (target != null) {
      final delta = target - _player;
      final dist = delta.distance;
      const speed = 0.42;
      if (dist > 0.005) {
        final step = math.min(dist, speed * dt);
        _player = _clampToArea(_player + delta / dist * step);
        dirty = true;
      } else {
        _moveTarget = null;
      }
    }

    if (_charging && !_stepDone) {
      _chargeProgress = math.min(1, _chargeProgress + dt / _chargeSeconds);
      dirty = true;
      if (_chargeProgress >= 1) _completeCharge();
    }

    final nowSec = elapsed.inMicroseconds / 1e6;
    if (dirty && nowSec - _lastUiPaintAt >= 1 / 20) {
      _lastUiPaintAt = nowSec;
      if (mounted) setState(() {});
    }
  }

  void _completeCharge() {
    if (_stepDone) return;
    _charging = false;
    _stepDone = true;
    if (_step.marker == _Marker.terminal) _oniRevealed = true;
    _flashMessage = _step.copy.successFlash;
    GameAudio.instance.playSfx(SfxId.reward);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
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
      _charging = false;
      _chargeProgress = 0;
      _flashMessage = null;
      _moveTarget = null;
      if (_index < 2) _oniRevealed = false;
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
      _charging = false;
      _chargeProgress = 0;
      _flashMessage = null;
      _moveTarget = null;
      _finished = false;
      _oniRevealed = false;
      _player = const Offset(0.5, 0.64);
    });
  }

  void _openGuideSection(String sectionId, {String? guideCardId}) {
    showHowToPlaySheet(
      context,
      initialSectionId: guideCardId == null ? sectionId : null,
      initialGuideCardId: guideCardId,
    );
  }

  Offset _clampToArea(Offset p) {
    final delta = p - _areaCenter;
    if (delta.distance <= _areaRadius) return p;
    return _areaCenter + delta / delta.distance * _areaRadius;
  }

  void _onArenaTap(Offset normalized) {
    if (_finished || _stepDone) return;
    if (_step.act == _Act.tapNext) return;
    setState(() => _moveTarget = _clampToArea(normalized));
    GameAudio.instance.playSfx(SfxId.uiTap);
  }

  void _onAction() {
    if (_stepDone || _step.act != _Act.chargeAtMarker) return;
    if (!_inMarkerRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('マーカーの近くまで移動してください')),
      );
      return;
    }
    if (_charging) return;
    GameAudio.instance.playSfx(SfxId.skillCast);
    setState(() {
      _charging = true;
      _chargeProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finishCopy = TutorialCopyCatalog.finishForSecondGame(widget.kind);
    final title = TutorialCopyCatalog.secondGameTutorialTitle(widget.kind);
    final showAction = _step.act == _Act.chargeAtMarker && !_stepDone;
    final showNext = _step.act == _Act.tapNext;

    return Scaffold(
      appBar: AppBar(
        title: Text('脱落後チュートリアル — $title'),
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
                  text: _step.copy.text,
                  accent: _accent,
                  done: _stepDone,
                  missionLabel: _missionLabel,
                  flash: _flashMessage,
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
                                  moveTarget: _moveTarget,
                                  showTerminal: _step.copy.showTerminal,
                                  showAccusation:
                                      _step.copy.showAccusationFacility,
                                  showCamera: _step.copy.showCamera,
                                  showRevealedOni:
                                      _oniRevealed || _step.copy.showRevealedOni,
                                  highlightMarker: _step.marker,
                                  inRange: _inMarkerRange,
                                  charging: _charging,
                                  chargeProgress: _chargeProgress,
                                  accent: _accent,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showAction && _charging)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _chargeProgress,
                              minHeight: 8,
                              backgroundColor:
                                  _accent.withValues(alpha: 0.15),
                              color: _accent,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          if (showAction)
                            Expanded(
                              child: JuicyTap(
                                onTap: _onAction,
                                sfx: SfxId.skillCast,
                                child: IgnorePointer(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _accent,
                                    ),
                                    onPressed: () {},
                                    icon: Icon(secondGameTutorialIcon(widget.kind)),
                                    label: Text(_step.actionLabel ?? '実行'),
                                  ),
                                ),
                              ),
                            ),
                          if (showNext) ...[
                            if (showAction) const SizedBox(width: 12),
                            JuicyTap(
                              onTap: _advance,
                              sfx: SfxId.uiTap,
                              child: IgnorePointer(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accent,
                                  ),
                                  onPressed: () {},
                                  child: const Text('次へ'),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.player,
    required this.moveTarget,
    required this.showTerminal,
    required this.showAccusation,
    required this.showCamera,
    required this.showRevealedOni,
    required this.highlightMarker,
    required this.inRange,
    required this.charging,
    required this.chargeProgress,
    required this.accent,
    required this.scheme,
  });

  final Offset player;
  final Offset? moveTarget;
  final bool showTerminal;
  final bool showAccusation;
  final bool showCamera;
  final bool showRevealedOni;
  final _Marker? highlightMarker;
  final bool inRange;
  final bool charging;
  final double chargeProgress;
  final Color accent;
  final ColorScheme scheme;

  static const _terminalPos = Offset(0.34, 0.36);
  static const _accusationPos = Offset(0.70, 0.50);
  static const _cameraPos = Offset(0.52, 0.28);
  static const _oniRevealPos = Offset(0.42, 0.22);

  Offset _px(Offset n, Size s) => Offset(n.dx * s.width, n.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = scheme.surfaceContainerHighest;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      bg,
    );

    final areaC = _px(const Offset(0.5, 0.5), size);
    final areaR = 0.42 * size.width;
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

    if (showTerminal) {
      _facility(
        canvas,
        _px(_terminalPos, size),
        '端子',
        highlight: highlightMarker == _Marker.terminal,
        inRange: highlightMarker == _Marker.terminal && inRange,
        charging: highlightMarker == _Marker.terminal && charging,
        progress: chargeProgress,
      );
    }

    if (showAccusation) {
      _facility(
        canvas,
        _px(_accusationPos, size),
        '告発',
        highlight: highlightMarker == _Marker.accusationFacility,
        inRange: highlightMarker == _Marker.accusationFacility && inRange,
        charging: highlightMarker == _Marker.accusationFacility && charging,
        progress: chargeProgress,
      );
    }

    if (showCamera) {
      _facility(
        canvas,
        _px(_cameraPos, size),
        'カメラ',
        highlight: highlightMarker == _Marker.camera,
        inRange: highlightMarker == _Marker.camera && inRange,
        charging: highlightMarker == _Marker.camera && charging,
        progress: chargeProgress,
      );
    }

    if (showRevealedOni) {
      _ghostDot(canvas, _px(_oniRevealPos, size), const Color(0xFFD64545), '鬼');
    }

    _ghostDot(canvas, _px(player, size), accent, 'あなた');
  }

  void _facility(
    Canvas canvas,
    Offset p,
    String label, {
    required bool highlight,
    required bool inRange,
    required bool charging,
    required double progress,
  }) {
    final base = highlight ? accent : scheme.primary;
    final radius = highlight ? 22.0 : 18.0;
    if (highlight) {
      canvas.drawCircle(
        p,
        radius + 8,
        Paint()
          ..color = base.withValues(alpha: inRange ? 0.28 : 0.12)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawCircle(
      p,
      radius,
      Paint()..color = base.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..color = base
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 2.5 : 1.5,
    );
    if (charging && highlight) {
      final sweep = progress * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: p, radius: radius + 4),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = base
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: base,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, p + Offset(-tp.width / 2, radius + 2));
  }

  void _ghostDot(Canvas canvas, Offset p, Color color, String label) {
    canvas.drawCircle(
      p,
      14,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      p,
      14,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, p + Offset(-tp.width / 2, 18));
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter old) =>
      old.player != player ||
      old.moveTarget != moveTarget ||
      old.showTerminal != showTerminal ||
      old.showAccusation != showAccusation ||
      old.showCamera != showCamera ||
      old.showRevealedOni != showRevealedOni ||
      old.highlightMarker != highlightMarker ||
      old.inRange != inRange ||
      old.charging != charging ||
      old.chargeProgress != chargeProgress;
}
