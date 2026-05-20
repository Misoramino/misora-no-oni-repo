# Game Event Areas

> 定数の一次ソース: `lib/game/game_config.dart` / 変更時の検証: [CHANGE_MAP.md](./CHANGE_MAP.md) § C

This file summarizes the current local MVP behavior for map event areas.

## Safe Zone

- Radius: `GameConfig.safeZoneRadiusMeters`
- Generated at match start, scaled by play area size.
- When a runner enters an available safe zone:
  - gains one stealth charge, up to `safeZoneMaxCharges`
  - resets local skill cooldowns for the player's equipped skills
  - the used safe zone relocates to a new point in the play area
  - it becomes unavailable until `safeZoneRespawnSeconds` passes
- Stealth charges are automatic defense resources, not active skills.
- One stealth charge is consumed to avoid one outside-area location reveal.
- Skill cooldowns are intentionally longer, so safe zones are a meaningful way to regain tempo.

## Info Broker

- Radius: `GameConfig.infoBrokerRadiusMeters`
- Generated at match start, scaled by play area size.
- When used:
  - gives one temporary oni intel line according to `OniIntelMode`
  - stores the oni intel trace on the map for about 10 minutes
  - relocates to a new point in the play area
  - becomes unavailable until `infoBrokerRespawnSeconds` passes

## Surveillance Camera

- Radius: `GameConfig.cameraTriggerRadiusMeters`
- Generated at match start as many small points, scaled by play area size.
- When a runner enters a camera radius:
  - emits a local match event
  - shows a small notification
  - the camera is marked triggered for the rest of the match

## Communication Jamming Zone

- Radius: `GameConfig.commJammingZoneRadiusMeters`
- Generated at match start, scaled by play area size.
- When inside the zone:
  - info broker intel may become noisy or partially locked depending on the current cycle
  - the zone alternates open/closed based on `commJammingCycleSeconds`

## Not Implemented Yet

- Heal zone / stamina zone
- Decoy broadcast tower
- Skill shop / loadout change area
- One-way gate or escape objective
- Team-only reveal area
