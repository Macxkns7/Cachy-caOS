#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MODULE_TARGET="$DATA_HOME/cachycaos/modules/webapps/router"
BIN_TARGET="$HOME/.local/bin/cachycaos-webapp-router"
BIN_SOURCE="$ROOT/../../../bin/cachycaos-webapp-router"
WEBAPPS_SOURCE="$ROOT/../app.sh"
WEBAPPS_TARGET="$DATA_HOME/cachycaos/modules/webapps/app.sh"
WEBAPPS_BIN_SOURCE="$ROOT/../../../bin/cachycaos-webapp"
WEBAPPS_BIN_TARGET="$HOME/.local/bin/cachycaos-webapp"
BACKUP_DIR="$DATA_HOME/cachycaos/webapps/backups"

die() {
  echo "Error: $*" >&2
  exit 1
}

[[ -f "$BIN_SOURCE" ]] || die "No se encontró el wrapper del comando."
[[ -f "$WEBAPPS_SOURCE" ]] || die "No se encontró el módulo WebApps."
[[ -f "$WEBAPPS_BIN_SOURCE" ]] ||
  die "No se encontró el wrapper de WebApps."

mkdir -p \
  "$MODULE_TARGET/extension" \
  "$MODULE_TARGET/lib" \
  "$(dirname -- "$BIN_TARGET")"

if [[ -f "$WEBAPPS_TARGET" ]]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  cp -a "$WEBAPPS_TARGET" "$BACKUP_DIR/webapps-app-$stamp.sh"
  echo "✓ Respaldo del módulo WebApps: $BACKUP_DIR/webapps-app-$stamp.sh"
fi

install -m 0755 "$WEBAPPS_SOURCE" "$WEBAPPS_TARGET"
install -m 0755 "$WEBAPPS_BIN_SOURCE" "$WEBAPPS_BIN_TARGET"
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
echo "✓ Integración WebApps instalada: $WEBAPPS_TARGET"
