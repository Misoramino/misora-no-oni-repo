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

## Key paths

- **`lib/screens/game_map_screen.dart`** — main game loop + map orchestration (large file; see [docs/CHANGE_MAP.md](docs/CHANGE_MAP.md) section H)
- **`lib/screens/title_screen.dart`** — app entry, online lobby navigation
- **`lib/screens/match_gallery_screen.dart`** — saved matches list
- **`lib/screens/match_replay_screen.dart`** — replay / timelapse
- **`lib/game/`** — rules, config, play area, match record
- **`lib/features/game_map/`** — map-only UI (HUD, prep, match bridge)
- **`lib/sync/`** — Firestore room session and events
- **`lib/services/`** — location, recording, local persistence
- **`lib/theme/`** — worldview profiles and `AppThemeFactory`
- **`docs/HANDBOOK.md`** — **start here** for handoff (humans & AI): doc index + verification commands
- **`docs/FILE_STRUCTURE.md`** — directory tree + Firebase plist/json cheat sheet (for sharing)
- **`docs/AI_HANDOFF.md`** — short English design priorities + links to the docs above
- **`docs/BLE_PROXIMITY.md`** — BLE proximity behavior notes

## Run

```bash
flutter pub get
flutter run
```
