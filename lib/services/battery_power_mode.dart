import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

/// 端末の低電力モード（省電力）検知。
abstract final class BatteryPowerMode {
  static final Battery _battery = Battery();

  static Future<bool> isLowPowerModeEnabled() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _battery.isInBatterySaveMode;
    } catch (_) {
      return false;
    }
  }
}
