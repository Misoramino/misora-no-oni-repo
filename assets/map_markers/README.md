# Map marker assets (optional)

Programmatic icons are generated at runtime when PNGs are missing.

To override per world, add PNGs (96×96 recommended):

```
assets/map_markers/{assetKey}/
  camera.png
  info_broker.png
  safe_zone.png
  player_default.png
  reveal.png
```

`assetKey` matches `WorldProfile.assetKey` (e.g. `cyber_night`, `pop_city`).

`pubspec.yaml` already includes `assets/map_markers/`. At runtime,
`MapMarkerIconRegistry` loads PNGs when present and falls back to programmatic icons.
