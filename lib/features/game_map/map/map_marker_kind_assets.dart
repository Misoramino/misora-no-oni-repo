import 'map_marker_kind.dart';

extension MapMarkerKindAssets on MapMarkerKind {
  /// `assets/map_markers/{assetKey}/{file}.png` のファイル名（拡張子なし）。
  String get assetFileName => switch (this) {
        MapMarkerKind.player => 'player_default',
        MapMarkerKind.playerRevealed => 'player_revealed',
        MapMarkerKind.oni => 'oni',
        MapMarkerKind.remoteOni => 'remote_oni',
        MapMarkerKind.remoteRunner => 'remote_runner',
        MapMarkerKind.remoteSpectator => 'remote_spectator',
        MapMarkerKind.camera => 'camera',
        MapMarkerKind.infoBroker => 'info_broker',
        MapMarkerKind.safeZone => 'safe_zone',
        MapMarkerKind.commJamming => 'comm_jamming',
        MapMarkerKind.trace => 'trace',
        MapMarkerKind.reveal => 'reveal',
        MapMarkerKind.anonymousReveal => 'anonymous_reveal',
        MapMarkerKind.oniIntel => 'oni_intel',
        MapMarkerKind.fakePosition => 'fake_position',
        MapMarkerKind.bodyThrow => 'body_throw',
        MapMarkerKind.accusationFacility => 'info_broker',
      };
}
