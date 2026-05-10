import 'dart:async';
import 'dart:math' as math;

import 'proximity_signal.dart';

abstract class ProximityService {
  Stream<ProximitySignal> watch();
  Future<void> start();
  Future<void> stop();
}

/// BLE導入前のモック。後で flutter_blue_plus 等へ差し替え可能。
class MockProximityService implements ProximityService {
  StreamController<ProximitySignal>? _controller;
  Timer? _timer;

  @override
  Stream<ProximitySignal> watch() {
    _controller ??= StreamController<ProximitySignal>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> start() async {
    _controller ??= StreamController<ProximitySignal>.broadcast();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final r = math.Random().nextDouble();
      final band = r < 0.55
          ? ProximityBand.far
          : r < 0.82
              ? ProximityBand.near
              : ProximityBand.contact;
      _controller?.add(
        ProximitySignal(
          band: band,
          confidence: (0.55 + math.Random().nextDouble() * 0.45),
          updatedAtUtc: DateTime.now().toUtc(),
          source: 'ble_mock',
        ),
      );
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
