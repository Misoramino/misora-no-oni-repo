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

  /// 情報量多め（旧ポップ向け。互換のため残す）
  static const rich = MapZoomLodPolicy(
    gimmickIconMinZoom: 13,
    detailMarkerMinZoom: 14,
    traceMarkerMinZoom: 13,
    revealMarkerMinZoom: 13,
    remotePlayerMinZoom: 12,
  );

  /// Cyber Night: 細マーカーはやや遅め、ギミックは標準寄り（スキャン主役で地図を圧しない）
  static const cyberNight = MapZoomLodPolicy(
    gimmickIconMinZoom: 14.5,
    detailMarkerMinZoom: 15.5,
    traceMarkerMinZoom: 15,
    revealMarkerMinZoom: 14.5,
    remotePlayerMinZoom: 13,
  );

  /// Pop City: 明るく楽しいが、ズームアウト時の過密を少し抑える
  static const popCity = MapZoomLodPolicy(
    gimmickIconMinZoom: 14,
    detailMarkerMinZoom: 14.5,
    traceMarkerMinZoom: 14,
    revealMarkerMinZoom: 14,
    remotePlayerMinZoom: 12.5,
  );

  /// Stealth Tactical: 情報制御・最小表示
  static const stealthTactical = MapZoomLodPolicy(
    gimmickIconMinZoom: 16,
    detailMarkerMinZoom: 17,
    traceMarkerMinZoom: 17,
    revealMarkerMinZoom: 16,
    remotePlayerMinZoom: 15,
  );

  /// Urban Horror: ズームアウト時はピンをさらに抑え、ノイズ・ビネットとバランス
  static const urbanHorror = MapZoomLodPolicy(
    gimmickIconMinZoom: 15.5,
    detailMarkerMinZoom: 16.5,
    traceMarkerMinZoom: 16,
    revealMarkerMinZoom: 15.5,
    remotePlayerMinZoom: 14.5,
  );
}
