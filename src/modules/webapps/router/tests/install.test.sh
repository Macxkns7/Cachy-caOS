#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
TEST_HOME="$TEMP_ROOT/home"

cleanup() {
  rm -rf -- "$TEMP_ROOT"
}

trap cleanup EXIT

export HOME="$TEST_HOME"
export XDG_DATA_HOME="$TEST_HOME/.local/share"

APPLICATIONS="$XDG_DATA_HOME/applications"
TARGET="$XDG_DATA_HOME/cachycaos/webapps/router-extension"
COMMAND="$HOME/.local/bin/cachycaos-webapp-router"

mkdir -p "$APPLICATIONS"

cat > "$APPLICATIONS/cachycaos-webapp-chatgpt.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=ChatGPT
X-CachycaOS-WebApp=true
X-CachycaOS-WebApp-URL=https://chatgpt.com
DESKTOP

cat > "$APPLICATIONS/cachycaos-webapp-youtube-music.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=YouTube Music
X-CachycaOS-WebApp=true
X-CachycaOS-WebApp-URL=https://music.youtube.com/library
DESKTOP

bash "$ROOT/install.sh" >/dev/null

[[ -x "$COMMAND" ]]
[[ -x "$XDG_DATA_HOME/cachycaos/modules/webapps/router/app.sh" ]]
[[ -f "$TARGET/manifest.json" ]]
[[ -f "$TARGET/routes.json" ]]

python3 - "$TARGET" <<'PYTHON'
import json
from pathlib import Path
import sys

target = Path(sys.argv[1])
manifest = json.loads((target / "manifest.json").read_text())
registry = json.loads((target / "routes.json").read_text())

assert manifest["host_permissions"] == [
    "https://chatgpt.com/*",
    "https://music.youtube.com/*",
]
assert [route["id"] for route in registry["routes"]] == [
    "chatgpt",
    "youtube-music",
]
PYTHON

cat > "$APPLICATIONS/cachycaos-webapp-github.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=GitHub
X-CachycaOS-WebApp=true
X-CachycaOS-WebApp-URL=https://github.com
DESKTOP

[[ "$("$COMMAND" sync --quiet)" == $'changed\t3' ]]
[[ "$("$COMMAND" sync --quiet)" == $'unchanged\t3' ]]

"$COMMAND" uninstall >/dev/null
[[ ! -e "$TARGET" ]]

echo "✓ WebApp Router: instalación aislada validada"
