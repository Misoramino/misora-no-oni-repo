# Oni Game AI Handoff

This document is the shortest path for another AI or developer to understand
the current design intent.

## Design Priorities

1. Prioritize tension and mind game over perfect positioning.
2. Use low-cost updates for far distance, richer feedback for near distance.
3. Keep personal data local by default; explicit opt-in before storing trails.
4. Build systems in layers so UI/worldview can be swapped without rewriting rules.

## Current Architecture

- `lib/screens/game_map_screen.dart`
  - Main local game loop (timer, out-of-area reveal, state transitions)
  - Play area editor (circle/polygon)
  - Match start/reset and consent handling
- `lib/game/*`
  - `game_config.dart`: gameplay constants
  - `play_area.dart`: geometry and GeoJSON conversion
  - `match_record.dart`: replay-ready saved data model
  - `trajectory_simplify.dart`: post-game thinning for low storage/load
  - `sampling_tier.dart`: GPS sampling tiers for dynamic performance
- `lib/services/*`
  - `location_service.dart`: location stream by sampling tier
  - `match_recorder.dart`: in-match trajectory capture
  - `match_archive_store.dart`: local archive storage
  - `play_area_store.dart`: saved play area
- `lib/screens/match_*`
  - gallery + replay with per-track visibility toggles
- `lib/theme/*`
  - worldview/theme entry point for style replacement

## Performance & Cost Rules (Intent)

- Keep map logic based on raw GPS, smooth only marker rendering.
- Avoid high-frequency write patterns for cloud sync.
- Prefer event-driven sync (capture/reveal/end) over constant full-state writes.
- Keep replay data compact (simplified and bounded point count).

## Online Visibility Rules

- Do not store live player coordinates in `rooms/{roomId}/members/{uid}`.
- `members` is for lightweight presence only: nickname, role, heartbeat, proximity band.
- Position disclosure should move through explicit reveal/event documents so the app can decide who is allowed to see each clue.
- Default gameplay should preserve uncertainty: neither oni nor runners get full live positions by joining a room.

## Planned Next Steps

1. BLE proximity band integration (near-distance confidence boost)
2. FCM event nudges for iOS-friendly foreground re-entry
3. Optional PNG marker art per `assets/map_markers/{assetKey}/`
4. Cloud Map Styling (Map IDs) for production map tiles

World Visual Pack (6 profiles, map JSON, markers, atmosphere, replay) is implemented — see `docs/ARCHITECTURE.md` § World Visual Pack.
