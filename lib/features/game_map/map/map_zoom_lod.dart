/// ズーム段階に応じた地図マーカー表示ポリシー。
class MapZoomLodPolicy {
  const MapZoomLodPolicy({
    this.gimmickIconMinZoom = 14,
    this.detailMarkerMinZoom = 15,
    this.traceMarkerMinZoom = 15,
    this.revealMarkerMinZoom = 14,
    this.remotePlayerMinZoom = 13,
  });

  /// ギミック（安全地帯・情報屋・カメラ）のアイコン Marker
  final double gimmickIconMinZoom;

  /// 痕跡・鬼情報など細かい Marker
  final double detailMarkerMinZoom;

  final double traceMarkerMinZoom;
  final double revealMarkerMinZoom;
  final double remotePlayerMinZoom;

  bool showGimmickIcons(double zoom) => zoom >= gimmickIconMinZoom;
  bool showDetailMarkers(double zoom) => zoom >= detailMarkerMinZoom;
  bool showTraceMarkers(double zoom) => zoom >= traceMarkerMinZoom;
  bool showRevealMarkers(double zoom) => zoom >= revealMarkerMinZoom;
  bool showRemotePlayers(double zoom) => zoom >= remotePlayerMinZoom;

  /// 情報量が少ない世界観（ホラー・タクティカル）
  static const sparse = MapZoomLodPolicy(
    gimmickIconMinZoom: 15,
    detailMarkerMinZoom: 16,
    traceMarkerMinZoom: 16,
    revealMarkerMinZoom: 15,
    remotePlayerMinZoom: 14,
  );

  /// 標準
  static const standard = MapZoomLodPolicy();

  /// 情報量多め（ポップ）
  static const rich = MapZoomLodPolicy(
    gimmickIconMinZoom: 13,
    detailMarkerMinZoom: 14,
    traceMarkerMinZoom: 13,
    revealMarkerMinZoom: 13,
    remotePlayerMinZoom: 12,
  );
}
