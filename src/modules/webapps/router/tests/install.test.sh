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
export XDG_CONFIG_HOME="$TEST_HOME/.config"

APPLICATIONS="$XDG_DATA_HOME/applications"
TARGET="$XDG_DATA_HOME/cachycaos/webapps/router-extension"
HYPR_TARGET="$XDG_CONFIG_HOME/hypr/cachycaos/webapps.lua"
COMMAND="$HOME/.local/bin/cachycaos-webapp-router"
WEBAPPS_COMMAND="$HOME/.local/bin/cachycaos-webapp"
WEBAPPS_MODULE="$XDG_DATA_HOME/cachycaos/modules/webapps/app.sh"
FAKE_BIN="$TEMP_ROOT/bin"
HYPR_LOG="$TEMP_ROOT/hyprctl.log"

mkdir -p "$APPLICATIONS" "$XDG_CONFIG_HOME/hypr" "$FAKE_BIN"

cat > "$XDG_CONFIG_HOME/hypr/hyprland.lua" <<'LUA'
require("cachycaos.webapps")
LUA

cat > "$FAKE_BIN/hyprctl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HYPR_LOG"
SH
chmod 0755 "$FAKE_BIN/hyprctl"
export HYPR_LOG
export PATH="$FAKE_BIN:$PATH"

cat > "$APPLICATIONS/cachycaos-webapp-chatgpt.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=ChatGPT
StartupWMClass=vivaldi-chatgpt.com__-Default
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
[[ -x "$WEBAPPS_COMMAND" ]]
[[ -x "$WEBAPPS_MODULE" ]]
grep -Fq 'sync --quiet' "$WEBAPPS_MODULE"
[[ -x "$XDG_DATA_HOME/cachycaos/modules/webapps/router/app.sh" ]]
[[ -f "$TARGET/manifest.json" ]]
[[ -f "$TARGET/routes.json" ]]
[[ -f "$HYPR_TARGET" ]]
grep -Fxq 'reload' "$HYPR_LOG"

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
assert registry["routes"][0]["window_class"] == (
    "vivaldi-chatgpt.com__-Default"
)
PYTHON

grep -Fq 'name = "nest-webapp-chatgpt-focus"' "$HYPR_TARGET"
grep -Fq 'class = "^vivaldi-chatgpt\\.com__.*-Default$"' "$HYPR_TARGET"
grep -Fq 'focus_on_activate = true' "$HYPR_TARGET"

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
grep -Fq 'WebApp Router is not installed' "$HYPR_TARGET"
[[ "$(grep -Fxc 'reload' "$HYPR_LOG")" -ge 2 ]]

echo "✓ WebApp Router: instalación aislada validada"
