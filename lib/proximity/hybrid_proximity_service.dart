import 'dart:async';
import 'dart:math' as math;

import '../game/game_config.dart';
import 'proximity_service.dart';
import 'proximity_signal.dart';

/// GPS（粗い中距離）と BLE デリゲート（近距離〜接触）を合成する。
///
/// [ingestGpsDistanceMeters] はゲームループ側から毎ティック呼ぶ想定。
/// `contact` は BLE 側のみが立てる（GPS は `near` で頭打ち）。
class HybridProximityService implements ProximityService {
  HybridProximityService({required ProximityService bleDelegate})
      : _ble = bleDelegate;

  final ProximityService _ble;

  StreamController<ProximitySignal>? _out;
  StreamSubscription<ProximitySignal>? _bleSub;

  ProximitySignal _lastBle = ProximitySignal(
    band: ProximityBand.none,
    confidence: 0.35,
    updatedAtUtc: DateTime.now().toUtc(),
    source: 'ble_pending',
  );

  double? _lastGpsDistanceMeters;

  @override
  Stream<ProximitySignal> watch() {
    _out ??= StreamController<ProximitySignal>.broadcast();
    return _out!.stream;
  }

  @override
  Future<void> start() async {
    _out ??= StreamController<ProximitySignal>.broadcast();
    await _ble.start();
    await _bleSub?.cancel();
    _bleSub = _ble.watch().listen((s) {
      _lastBle = s;
      _emitMerged();
    });
  }

  @override
  Future<void> stop() async {
    await _bleSub?.cancel();
    _bleSub = null;
    await _ble.stop();
    await _out?.close();
    _out = null;
  }

  @override
  void ingestGpsDistanceMeters(double distanceToOniMeters) {
    _lastGpsDistanceMeters = distanceToOniMeters;
    _emitMerged();
  }

  ProximityBand _bandFromGps(double d) {
    if (d > GameConfig.warningDistanceMeters) return ProximityBand.none;
    if (d > GameConfig.dangerDistanceMeters) return ProximityBand.far;
    return ProximityBand.near;
  }

  void _emitMerged() {
    final ctrl = _out;
    if (ctrl == null || ctrl.isClosed) return;

    final gpsBand = _lastGpsDistanceMeters == null
        ? ProximityBand.none
        : _bandFromGps(_lastGpsDistanceMeters!);

    final merged = mergeProximityBands(gpsBand, _lastBle.band);
    final baseConf = merged == ProximityBand.none ? 0.28 : 0.58;
    final confidence =
        math.min(1.0, math.max(baseConf, _lastBle.confidence));

    ctrl.add(
      ProximitySignal(
        band: merged,
        confidence: confidence,
        updatedAtUtc: DateTime.now().toUtc(),
        source: 'hybrid:g=${gpsBand.name}+${_lastBle.source}',
      ),
    );
  }
}
