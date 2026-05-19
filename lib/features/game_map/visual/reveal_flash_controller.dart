import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../theme/world_visual_pack.dart';

/// reveal フラッシュの ON/OFF とノイズ seed を管理。
class RevealFlashController {
  RevealFlashController(this._onChanged);

  final VoidCallback _onChanged;
  Timer? _offTimer;

  bool active = false;
  double noiseSeed = 0;

  void trigger(WorldVisualPack pack) {
    if (pack.revealFlashColor == null) return;
    _offTimer?.cancel();
    active = true;
    noiseSeed = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    _onChanged();
    _offTimer = Timer(Duration(milliseconds: pack.revealFlashDurationMs), () {
      active = false;
      _onChanged();
    });
  }

  void dispose() {
    _offTimer?.cancel();
  }
}
