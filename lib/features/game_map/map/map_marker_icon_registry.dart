import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/world_profile.dart';
import '../../../theme/world_profile_tokens.dart';
import '../../../theme/world_visual_pack.dart';
import 'map_marker_icon_factory.dart';
import 'map_marker_kind.dart';

/// 試合中に使うマーカーアイコンのキャッシュ（profile 変更時に作り直す）。
class MapMarkerIconRegistry {
  MapMarkerIconRegistry(this.pack);

  final WorldVisualPack pack;
  final Map<MapMarkerKind, BitmapDescriptor> _icons = {};
  bool _ready = false;

  bool get isReady => _ready;
  WorldProfileTokens get tokens => pack.tokens;

  Future<void> warmUp() async {
    _icons.clear();
    final kinds = MapMarkerKind.values;
    final assetKey = pack.profile.assetKey;
    for (final kind in kinds) {
      _icons[kind] = await MapMarkerIconFactory.create(
        kind: kind,
        tokens: pack.tokens,
        profileAssetKey: assetKey,
      );
    }
    _ready = true;
  }

  BitmapDescriptor? icon(MapMarkerKind kind) => _icons[kind];

  BitmapDescriptor iconOrHue(MapMarkerKind kind, double hue) {
    return _icons[kind] ?? BitmapDescriptor.defaultMarkerWithHue(hue);
  }
}
