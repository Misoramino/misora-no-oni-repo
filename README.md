# Oni Game

Urban GPS tag game prototype with tension-focused design:

- Far distance: coarse tracking is acceptable
- Near distance: high-pressure experience is prioritized
- Replay: opt-in local timeline archive after each match

## Core Principles

- Gameplay tension over perfect geolocation
- Privacy-by-default (opt-in storage for trajectory)
- Layered architecture for easy UI/worldview replacement
- Cost-aware sync design (event-first, low-frequency presence)

## Current Features

- Local playable loop (start, timer, win/lose)
- Play area editor (circle and polygon)
- Out-of-area reveal event with grace by meters/seconds
- Trajectory archive and timelapse replay
- Per-track visibility toggle in replay
- Dynamic GPS sampling tiers + marker smoothing

## Key Paths

- `lib/screens/game_map_screen.dart`: game runtime and area editor
- `lib/screens/match_gallery_screen.dart`: saved matches list
- `lib/screens/match_replay_screen.dart`: replay/timelapse
- `lib/game`: rules/data model/simplification
- `lib/services`: location and local persistence
- `lib/theme`: worldview-ready app theme entry
- `docs/AI_HANDOFF.md`: architecture + intent for handoff

## Run

```bash
flutter pub get
flutter run
```
