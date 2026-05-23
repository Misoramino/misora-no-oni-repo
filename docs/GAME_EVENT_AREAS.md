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
  - gives one temporary oni intel line according to `OniIntelMode` (direction, distance band, or fragmented text — not a live GPS pin on the oni)
  - stores a **clue note** for about 10 minutes: HUD list + optional map pin at the pickup point (tap to re-read text; no need to travel there; info broker itself has already moved)
  - relocates to a new point in the play area
  - becomes unavailable until `infoBrokerRespawnSeconds` passes
- Not implemented yet: true “10 minutes ago” path history from stored hunter positions; anonymous “someone was here” traces

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
- **Host only**: positions are snapped to the nearest road via Google Roads API (`GOOGLE_MAPS_API_KEY` dart-define) when configured, then stored in `matchStart.eventAreas` so all devices share the same points. Without the key or when no road is nearby, random in-play-area placement is used.
- When inside the zone:
  - info broker intel may become noisy or partially locked depending on the current cycle
  - the zone alternates open/closed based on `commJammingCycleSeconds`

## Accusation facility (告発施設)

- One point per match (`GeneratedGimmicks.accusationFacility`), radius `GameConfig.accusationFacilityRadiusMeters`
- **3+ players** only. Unlock: any elimination **or** 60% of match time (`accusation_unlocked` from host)
- Runners enter radius → pick a player → accuse. Correct hunter UID → instant runner team win. Wrong → accuser full reveal + spent for match
- Werewolf cannot accuse. Copy per world profile: `lib/theme/accusation_facility_copy.dart` (Astronomy: 宇宙連合・地球支部)

## Not Implemented Yet

- Heal zone / stamina zone
- Decoy broadcast tower
- Skill shop / loadout change area
- One-way gate or escape objective
- Team-only reveal area
