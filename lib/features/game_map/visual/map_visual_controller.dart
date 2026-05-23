import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/map_style_loader.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_visual_pack.dart';
import '../../../theme/world_visual_pack_factory.dart';
import '../map/avatar_pin_compositor.dart';
import '../map/map_marker_icon_registry.dart';

/// 地図スタイル・マーカーアイコン・写真ピンの適用（GameMapScreen から委譲）。
class MapVisualController {
  MapVisualController(WorldProfile profile)
      : pack = WorldVisualPackFactory.of(profile);

  WorldVisualPack pack;
  MapMarkerIconRegistry? markerRegistry;
  BitmapDescriptor? playerAvatarIcon;
  double mapZoom = 16;
  double markerIconScale = 1.0;

  /// [GoogleMap.style] に渡す JSON（読み込み後）。
  String? mapStyleJson;

  Future<void> reloadForProfile(WorldProfile profile) async {
    pack = WorldVisualPackFactory.of(profile);
    mapStyleJson = await MapStyleLoader.load(pack.mapStyleAssetPath);
    markerRegistry = MapMarkerIconRegistry(pack, iconScale: markerIconScale);
    await markerRegistry!.warmUp();
    playerAvatarIcon = null;
  }

  Future<void> applyMarkerIconScale(double scale) async {
    markerIconScale = scale;
    markerRegistry = MapMarkerIconRegistry(pack, iconScale: scale);
    await markerRegistry!.warmUp();
  }

  Future<void> refreshPlayerAvatar({
    required String? localPath,
    required bool usePhoto,
    required bool revealedStyle,
    double iconScale = 1.0,
  }) async {
    if (!usePhoto || localPath == null || localPath.isEmpty) {
      playerAvatarIcon = null;
      return;
    }
    playerAvatarIcon = await AvatarPinCompositor.fromFilePath(
      path: localPath,
      tokens: pack.tokens,
      revealedStyle: revealedStyle,
      iconScale: iconScale,
    );
  }

  void updateZoom(double zoom) {
    mapZoom = zoom;
  }
}
