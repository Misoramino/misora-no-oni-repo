import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../theme/world_fx_profile.dart';
import '../../../theme/world_visual_pack.dart';

/// 暴露・捕獲など「決定的瞬間」のフラッシュとバナー表示。
class WorldMomentFlashController {
  WorldMomentFlashController(this._onChanged);

  final VoidCallback _onChanged;
  Timer? _offTimer;

  bool active = false;
  WorldMomentKind? momentKind;
  double noiseSeed = 0;
  int flashDurationMs = 420;
  double flashOpacity = 0.55;

  void trigger({
    required WorldVisualPack pack,
    required WorldFxProfile fx,
    required WorldMomentKind kind,
  }) {
    _offTimer?.cancel();
    active = true;
    momentKind = kind;
    noiseSeed = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    flashDurationMs = fx.flashDurationMsFor(kind);
    flashOpacity = fx.flashOpacityFor(kind);
    _onChanged();
    _offTimer = Timer(Duration(milliseconds: flashDurationMs), () {
      active = false;
      momentKind = null;
      _onChanged();
    });
  }

  void dispose() {
    _offTimer?.cancel();
  }
}
