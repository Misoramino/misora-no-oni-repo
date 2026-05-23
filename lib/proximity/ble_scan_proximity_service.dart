import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_game_protocol.dart';
import 'ble_platform.dart';
import 'proximity_service.dart';
import 'proximity_signal.dart';

/// 周辺の **同一ルーム** BLE アドバタイズ RSSI から近接帯を推定する。
///
/// Web / 非モバイルでは常に [ProximityBand.none]。
class BleScanProximityService extends ProximityService {
  BleScanProximityService({this.scanFilter});

  BleGameScanFilter? scanFilter;

  StreamController<ProximitySignal>? _out;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  Timer? _scanTimer;
  bool _scanInFlight = false;

  @override
  Stream<ProximitySignal> watch() {
    _out ??= StreamController<ProximitySignal>.broadcast();
    return _out!.stream;
  }

  @override
  Future<void> start() async {
    _out ??= StreamController<ProximitySignal>.broadcast();
    await _adapterSub?.cancel();
    _scanTimer?.cancel();

    if (kIsWeb || !defaultTargetPlatformIsMobile) {
      _emit(ProximityBand.none, 0.25, 'ble_unsupported_platform');
      return;
    }

    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        unawaited(_scanOnce());
      } else {
        _emit(ProximityBand.none, 0.3, 'ble_adapter_${state.name}');
      }
    });

    _scanTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_scanOnce());
    });
    unawaited(_scanOnce());
  }

  @override
  Future<void> stop() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _adapterSub?.cancel();
    _adapterSub = null;
    _scanInFlight = false;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _out?.close();
    _out = null;
  }

  Future<void> _scanOnce() async {
    if (_scanInFlight) return;
    final ctrl = _out;
    if (ctrl == null || ctrl.isClosed) return;

    if (kIsWeb || !defaultTargetPlatformIsMobile) {
      _emit(ProximityBand.none, 0.25, 'ble_unsupported_platform');
      return;
    }

    final filter = scanFilter;
    if (filter == null) {
      _emit(ProximityBand.none, 0.4, 'ble_no_match_filter');
      return;
    }

    _scanInFlight = true;
    try {
      if (!await FlutterBluePlus.isSupported) {
        _emit(ProximityBand.none, 0.25, 'ble_not_supported');
        return;
      }
      final adapter = await FlutterBluePlus.adapterState.first;
      if (adapter != BluetoothAdapterState.on) {
        _emit(ProximityBand.none, 0.35, 'ble_adapter_${adapter.name}');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final scan = await Permission.bluetoothScan.request();
        final conn = await Permission.bluetoothConnect.request();
        if (!scan.isGranted || !conn.isGranted) {
          _emit(ProximityBand.none, 0.35, 'ble_permission_denied');
          return;
        }
      }

      await FlutterBluePlus.startScan(
        withServices: [Guid(BleGameProtocol.serviceUuid)],
        timeout: const Duration(seconds: 2),
        androidUsesFineLocation: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2200));

      final list = FlutterBluePlus.lastScanResults;
      if (list.isEmpty) {
        _emit(ProximityBand.none, 0.4, 'ble_no_peer');
        return;
      }
      var best = -1000;
      for (final r in list) {
        final mfg = r.advertisementData.manufacturerData;
        final match = mfg.entries.any(
          (e) =>
              e.key == BleGameProtocol.manufacturerId &&
              BleGameProtocol.matchesPayload(
                e.value,
                roomId: filter.roomId,
                sessionKey: filter.sessionKey,
                requireOniBeacon: true,
              ),
        );
        if (!match) continue;
        if (r.rssi > best) best = r.rssi;
      }
      if (best <= -1000) {
        _emit(ProximityBand.none, 0.45, 'ble_no_room_peer');
        return;
      }
      _emitFromRssi(best);
    } catch (e) {
      _emit(ProximityBand.none, 0.25, 'ble_scan_error');
      if (kDebugMode) {
        debugPrint('BleScanProximityService: $e');
      }
    } finally {
      _scanInFlight = false;
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  void _emitFromRssi(int rssi) {
    final band = switch (rssi) {
      >= -62 => ProximityBand.contact,
      >= -75 => ProximityBand.near,
      >= -90 => ProximityBand.far,
      _ => ProximityBand.none,
    };
    final conf = switch (band) {
      ProximityBand.none => 0.42,
      ProximityBand.far => 0.55,
      ProximityBand.near => 0.72,
      ProximityBand.contact => 0.88,
    };
    _emit(band, conf, 'ble_rssi_$rssi');
  }

  void _emit(ProximityBand band, double confidence, String source) {
    final ctrl = _out;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(
      ProximitySignal(
        band: band,
        confidence: confidence.clamp(0.0, 1.0),
        updatedAtUtc: DateTime.now().toUtc(),
        source: source,
      ),
    );
  }
}
