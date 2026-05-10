enum OniIntelMode {
  directionOnly,
  distanceBandOnly,
  fragmented,
}

extension OniIntelModeLabel on OniIntelMode {
  String get label {
    switch (this) {
      case OniIntelMode.directionOnly:
        return '方角のみ';
      case OniIntelMode.distanceBandOnly:
        return '距離帯のみ';
      case OniIntelMode.fragmented:
        return '断片情報';
    }
  }
}
