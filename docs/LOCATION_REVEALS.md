# Location reveals (design)

## Goals

- Mix **identified** reveals (name + map pin) with **anonymous** clues (position or text only) so players deduce who is where.
- Fake tools must look like ordinary leaks, not labeled “decoy” on the opponent’s UI.

## Reveal tiers

| Tier | Examples | Opponent sees |
|------|----------|----------------|
| Identified | Area overflow, infection pulse, body throw, fake intel reveal, **oni info broker** | Player label + violet reveal pin |
| Text-only | Info broker (runner: direction / distance / fragments) | HUD + clue note at broker pickup |
| Anonymous | Periodic floor (40s), surveillance camera pass | Pin without a name (“不明な痕跡”) |

## Skills (intended play)

### Fake position (`fake_position`)

Runner skill: while active, **location reveals point at a wrong place** (decoy ahead on bearing, drifts ~2.8 m/s). Identified reveals during the effect use decoy coordinates. No “偽位置” map marker for others.

### Fake intel reveal (`fake_intel_reveal`) — **oni (hunter) skill only**

Oni misdirection: frame self or a runner at a false coordinate with a **cover story** from `RevealReasonPool` (same summaries as real leaks).

### Body double (planned)

Alternative to pure fake position: one activation leaks **both** real and decoy positions. Not implemented yet.

### Infection

Runner within ~`infectionTriggerDistanceMeters` of the oni for ~`infectionExposureSeconds`, then periodic **identified** reveals every `infectionRevealIntervalSeconds` (uses fake-position decoy if active). Pre-infection warnings for runners.

## Anonymous reveals (implemented)

### Periodic (40s)

- Bucket per `elapsedSeconds ~/ 40`
- All clients derive the same target UID (`gimmickSeed` + sorted assignment keys)
- **Only the selected client** publishes Firestore `anonymous_reveal`
- Map layer “痕跡”: cyan `不明な痕跡` markers
- Hunters and runners can be selected

### Surveillance camera

- Runner enters camera radius → anonymous reveal with camera reason from pool
- No player name on the pin

## Info broker (implemented)

### Runner

- Text intel: oni direction, distance band, fragment lines
- Clue memo at pickup point (~10 min), not live oni GPS
- Personal cooldown: `infoBrokerCooldownSeconds` (35s)
- Shared gimmick respawn: `infoBrokerRespawnSeconds` (45s)

### Oni (hunter) — P3

- Same map gimmick; **hunter role only** (not werewolf in runner form)
- On use: random **one runner** from match assignments
- Firestore event `oni_info_broker` with `targetUid` → **target runner device** publishes a normal `reveal` at their GPS (or fake-position decoy if active)
- No constant live location stream; one identified pin per use
- Hunter cooldown: `oniInfoBrokerCooldownSeconds` (90s), longer than runner
- Requires online Firestore match

## Accusation failure reveal

- Wrong accuse at the accusation facility → accuser gets one **identified** reveal (`accusation_failed`)

## Not implemented yet

- “10 minutes ago” oni path from `hunter_position` history
- `trace_drop` sync to other devices
- Polyline reveal trails
- Photo pins for remote players (local-only MVP elsewhere)

## Code pointers

- `lib/features/game_map/logic/reveal_reason_pool.dart`
- `lib/game/anonymous_reveal_trace.dart`
- `lib/game/oni_info_broker.dart`
- `lib/screens/game_map_screen.dart` — broker + reveal handlers
- `firestore.rules` — `reveal`, `anonymous_reveal`, `info_broker`, `oni_info_broker`
