import '../sync/firestore_room_session.dart';
import '../theme/world_profile.dart';

/// [RoomLobbyScreen] への名前付きルート（画面クラスを import しない側用）。
abstract final class RoomLobbyRoute {
  static const name = '/room-lobby';
}

class RoomLobbyRouteArgs {
  const RoomLobbyRouteArgs({this.existingSession, this.worldProfile});

  final FirestoreRoomSession? existingSession;
  final WorldProfile? worldProfile;
}
