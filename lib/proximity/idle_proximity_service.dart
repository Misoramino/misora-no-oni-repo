import 'dart:async';

import 'proximity_service.dart';
import 'proximity_signal.dart';

/// 本番向け: BLE オフ・テストモードオフ時は近接を常に none（ランダム捕獲を防ぐ）。
class IdleProximityService extends ProximityService {
  StreamController<ProximitySignal>? _controller;

  @override
  Stream<ProximitySignal> watch() {
    _controller ??= StreamController<ProximitySignal>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> start() async {
    _controller ??= StreamController<ProximitySignal>.broadcast();
    _emitNone();
  }

  @override
  Future<void> stop() async {
    await _controller?.close();
    _controller = null;
  }

  void _emitNone() {
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(
      ProximitySignal(
        band: ProximityBand.none,
        confidence: 0.35,
        updatedAtUtc: DateTime.now().toUtc(),
        source: 'idle',
      ),
    );
  }
}
