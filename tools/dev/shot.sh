#!/usr/bin/env bash
# Render a screenshot of any scene for look-dev.   usage: tools/dev/shot.sh <out-name> [game args...]
#   tools/dev/shot.sh castle --scene=castle --preset=at_castle --shot-delay=3
# Env: GODOT (path to Godot console exe), SIZE (default 1280x720)
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/Users/admin/tools/godot/Godot_v4.7.2-stable_win64_console.exe}"
SIZE="${SIZE:-1280x720}"
NAME="$1"; shift
mkdir -p "$ROOT/shots"
# refresh the class_name cache / imports (new scripts, new audio) - quick when nothing changed
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1
"$GODOT" --path "$ROOT/game" --resolution "$SIZE" --position 40,40 -- --shot="$ROOT/shots/$NAME.png" "$@" 2>&1 \
  | grep -vE '^\[ *[0-9]+%|^\s*$|^Godot Engine|^OpenGL API' | head -${LINES_MAX:-40}
echo "-> $ROOT/shots/$NAME.png"
