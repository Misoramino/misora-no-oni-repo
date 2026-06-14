import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ギミック使用後、地点移動を遅延適用するための予約。
class PendingGimmickRelocate {
  const PendingGimmickRelocate({
    required this.kind,
    required this.index,
    required this.position,
    required this.applyAt,
  });

  /// `safe_zone` | `info_broker`
  final String kind;
  final int index;
  final LatLng position;
  final DateTime applyAt;
}
