#!/usr/bin/env bash
# Exports the Web preset to ./export/index.html. Override the binary with GODOT=/path/to/godot.
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-}"
if [ -z "$GODOT" ]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT="godot"
  elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
  else
    echo "Godot not found. Install it or set GODOT=/path/to/godot" >&2
    exit 1
  fi
fi

mkdir -p export
"$GODOT" --headless --path . --export-release "Web" "$(pwd)/export/index.html"
echo "Exported to $(pwd)/export/index.html"
echo "Serve with: python3 -m http.server 8000 --directory export"
