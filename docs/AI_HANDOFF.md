# Oni Game AI Handoff (short)

For **where to edit and what to run**, use the Japanese hub:

- **[docs/HANDBOOK.md](HANDBOOK.md)** — entry order, doc index, mandatory `flutter analyze` / `flutter test`
- **[docs/CHANGE_MAP.md](CHANGE_MAP.md)** — topic → files → targeted tests

Technical module tree (JP): **[docs/ARCHITECTURE.md](ARCHITECTURE.md)**

---

## Design priorities (unchanged)

1. Prioritize tension and mind game over perfect positioning.
2. Use low-cost updates for far distance, richer feedback for near distance.
3. Keep personal data local by default; explicit opt-in before storing trails.
4. Build systems in layers so UI/worldview can be swapped without rewriting rules.

## Online visibility (invariant)

- Do not store live GPS in `rooms/{roomId}/members/{uid}`; presence fields only.
- Position disclosure flows through explicit events / reveals, not full-state sync.

## Planned directions (reference only)

- BLE proximity polish, optional FCM nudges, map marker art, Cloud Map Styling — see ARCHITECTURE § World Visual Pack for what is already implemented.
