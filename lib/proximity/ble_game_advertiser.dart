import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/foundation.dart';

import 'ble_game_protocol.dart';
import 'ble_platform.dart';

/// 試合中のみ ON。BLE オン端末が同一ルーム向けアドバタイズを出す。
class BleGameAdvertiser {
  bool _active = false;

  Future<void> start(BleGameScanFilter filter) async {
    if (kIsWeb || !defaultTargetPlatformIsMobile) return;
    try {
      if (!await BlePeripheral.isSupported()) return;
      await stop();
      await BlePeripheral.initialize();
      await BlePeripheral.addService(
        BleService(
          uuid: BleGameProtocol.serviceUuid,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: '6f6e6900-0002-4000-8000-00805f9b34fb',
              properties: [CharacteristicProperties.read.index],
              permissions: [AttributePermissions.readable.index],
              value: Uint8List.fromList([1]),
            ),
          ],
        ),
      );
      await BlePeripheral.startAdvertising(
        services: [BleGameProtocol.serviceUuid],
        localName: 'OniGame',
        manufacturerData: ManufacturerData(
          manufacturerId: BleGameProtocol.manufacturerId,
          data: Uint8List.fromList(filter.manufacturerPayload),
        ),
        addManufacturerDataInScanResponse: true,
      );
      _active = true;
    } catch (e) {
      _active = false;
      if (kDebugMode) {
        debugPrint('BleGameAdvertiser.start: $e');
      }
    }
  }

  Future<void> stop() async {
    if (!_active && !defaultTargetPlatformIsMobile) return;
    try {
      await BlePeripheral.stopAdvertising();
      await BlePeripheral.clearServices();
    } catch (_) {}
    _active = false;
  }
}
