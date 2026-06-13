from pathlib import Path

path = Path("lib/screens/game_map_screen.dart")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "import 'room_lobby_screen.dart';",
    "import '../navigation/room_lobby_route.dart';",
)
old = """    final returned = await AppNav.push<FirestoreRoomSession?>(
      context,
      (_) => RoomLobbyScreen(existingSession: fs),
      worldProfile: _activeProfile,
    );"""
new = """    final returned = await Navigator.of(context).pushNamed<FirestoreRoomSession?>(
      RoomLobbyRoute.name,
      arguments: RoomLobbyRouteArgs(
        existingSession: fs,
        worldProfile: _activeProfile,
      ),
    );"""
if old not in text:
    raise SystemExit("old block not found")
text = text.replace(old, new)
path.write_text(text, encoding="utf-8", newline="\n")
path.read_bytes().decode("utf-8")
print("patched ok")
