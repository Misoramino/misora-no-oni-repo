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


importers: dict[str, set[str]] = {k: set() for k in graph}
for node, imps in graph.items():
    for imp in imps:
        target = resolve(imp, node)
        if target and target in graph:
            importers[target].add(node)

start = "lib/screens/game_map_screen.dart"
targets = {
    p
    for p, srcs in importers.items()
    if "game_map_screen.dart" in open(p, encoding="utf-8", errors="ignore").read()
    or any("game_map_screen.dart" in imp for imp in graph.get(p, ()))
}
targets |= importers["lib/screens/game_map_screen.dart"]

# files that directly import game_map_screen
direct = {
    p
    for p, imps in graph.items()
    if any("game_map_screen.dart" in imp for imp in imps)
}
print("direct importers:", sorted(direct))

for target in sorted(direct):
    path = None
    q = deque([(start, [start])])
    seen: set[str] = set()
    while q:
        node, trail = q.popleft()
        if node == target:
            path = trail
            break
        if node in seen:
            continue
        seen.add(node)
        for imp in graph.get(node, ()):
            resolved = resolve(imp, node)
            if resolved and resolved in graph:
                q.append((resolved, trail + [resolved]))
    print(f"\n=== path to {target} ===")
    print(" -> ".join(path) if path else "(no path)")
