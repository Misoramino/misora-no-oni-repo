# Firestore room session — responsibility map

実装: `lib/sync/firestore_room_session.dart`（単一クラス、挙動変更なし）。

| 領域 | 主な API |
|------|----------|
| **Join / Lobby** | `join`, `lobbyMembers`, `fetchLatestLobbyPlayAreaEvent`, play area proposals |
| **Room events** | `publishRoomEvent`, `publishHostRoomEvent`, `startRoomEventsListener` |
| **Match control** | `publishMatchStart`, `publishMatchEnd`, `publishMatchEndRescue`, `updateRoomPhase` |
| **Host authority** | `transferHost`, `claimHostIfAbsent` |
| **Presence** | `publishPresence`, `publishAppLifecycle`, `publishPrepReady`, heartbeat |
| **Inspector feed** | `publishInspectorFeedPosition`, `inspectorFeed` |
| **Archive upload** | `publishMatchArchiveFull`, `publishMatchTrackChunk`, `publishMatchArchiveMeta` |
| **Archive download** | `fetchMergedMatchArchive`, `bindRoomForArchiveFetch` |
| **Disconnect** | `disconnect` |

将来 part / service 分割するときのガイドです。
