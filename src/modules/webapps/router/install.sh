#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MODULE_TARGET="$DATA_HOME/cachycaos/modules/webapps/router"
BIN_TARGET="$HOME/.local/bin/cachycaos-webapp-router"
BIN_SOURCE="$ROOT/../../../bin/cachycaos-webapp-router"

die() {
  echo "Error: $*" >&2
  exit 1
}

[[ -f "$BIN_SOURCE" ]] || die "No se encontró el wrapper del comando."

mkdir -p \
  "$MODULE_TARGET/extension" \
  "$MODULE_TARGET/lib" \
  "$(dirname -- "$BIN_TARGET")"

install -m 0755 "$ROOT/app.sh" "$MODULE_TARGET/app.sh"
install -m 0755 "$ROOT/lib/registry.py" \
  "$MODULE_TARGET/lib/registry.py"

for file in \
  background.js \
  manifest.json \
  popup.css \
  popup.html \
  popup.js \
  router-core.mjs \
  routes.json; do
  install -m 0644 "$ROOT/extension/$file" \
    "$MODULE_TARGET/extension/$file"
done

install -m 0755 "$BIN_SOURCE" "$BIN_TARGET"

"$MODULE_TARGET/app.sh" install

echo
echo "✓ Comando instalado: $BIN_TARGET"
