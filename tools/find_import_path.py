import os
import re
from collections import deque

root = "lib"
graph: dict[str, set[str]] = {}

for dirpath, _, files in os.walk(root):
    for name in files:
        if not name.endswith(".dart"):
            continue
        path = os.path.join(dirpath, name).replace("\\", "/")
        text = open(path, encoding="utf-8", errors="ignore").read()
        imps: set[str] = set()
        for m in re.finditer(r"^import\s+'([^']+)'", text, re.M):
            imps.add(m.group(1))
        for m in re.finditer(r'^import\s+"([^"]+)"', text, re.M):
            imps.add(m.group(1))
        graph[path] = imps


def resolve(imp: str, base: str) -> str | None:
    if imp.startswith("package:oni_game/"):
        return "lib/" + imp[len("package:oni_game/") :]
    if imp.startswith("dart:") or imp.startswith("package:"):
        return None
    base_dir = os.path.dirname(base).replace("\\", "/")
    return os.path.normpath(os.path.join(base_dir, imp)).replace("\\", "/")


def find_path(start: str, target: str) -> list[str] | None:
    q = deque([(start, [start])])
    seen: set[str] = set()
    while q:
        node, path = q.popleft()
        if node == target:
            return path
        if node in seen:
            continue
        seen.add(node)
        for imp in graph.get(node, ()):
            resolved = resolve(imp, node)
            if resolved and resolved in graph:
                q.append((resolved, path + [resolved]))
    return None


for target in [
    "lib/screens/title_screen.dart",
    "lib/screens/room_lobby_screen.dart",
    "lib/app.dart",
]:
    path = find_path("lib/screens/game_map_screen.dart", target)
    print(f"=== to {target} ===")
    if path:
        print(" -> ".join(path))
    else:
        print("(no path)")
