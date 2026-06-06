# ONI PIN

**GPS × ONI GAME** — Urban GPS tag game prototype with tension-focused design:

## Brand assets (`assets/branding/`)

| File | Use |
|------|-----|
| `app_icon.png` | Home screen (1024×1024, symbol only) — `dart run flutter_launcher_icons` |
| `brand_logo.png` | Title screen, README, share images (ONI PIN + subtitle) |
| `splash_logo.png` | App icon source (launcher); in-app uses geometric `ThemedGeometricLogo` |

Launch sound ON/OFF: volume icon on the title screen (persisted locally).

- Far distance: coarse tracking is acceptable
- Near distance: high-pressure experience is prioritized
- Replay: opt-in local timeline archive after each match

## Core Principles

- Gameplay tension over perfect geolocation
- Privacy-by-default (opt-in storage for trajectory)
- Layered architecture for easy UI/worldview replacement
- Cost-aware sync design (event-first, low-frequency presence)

## Current Features (v2)

- **Online rooms** — Firestore lobby, host sync, abort vote
- **Match presets** — Casual / Standard / Intense (duration, area, gimmick density)
- **Accusation weight modes** — Instant win, eliminate oni, or point scoring
- **Second game** — Spectral operative (camera jack, territory) and revenant oni sabotage after elimination
- **HUD** — Phase label, event feed line, skill cooldown pin on long-press, facility highlight on first elimination
- **Roles & skills** — Oni, runners, hunter, werewolf, modifiers, fake position, body throw, capture zone, etc.
- **Play area editor** — Circle / polygon, saved slots, GeoJSON import/export
- **Trajectory archive** — Opt-in local replay after each match
- **6 world profiles** — Map style, atmosphere, launch branding per theme
- **Audio** — BGM and ambient per world (`assets/audio/`)

Release notes: [CHANGELOG.md](CHANGELOG.md)

## Key paths

- **`lib/screens/game_map_screen.dart`** — main game orchestrator (split into `part` files; see index below)
- **`lib/features/game_map/game_map_screen_index.dart`** — part file map for AI / maintainers
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
