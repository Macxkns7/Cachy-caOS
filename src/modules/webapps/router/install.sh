#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/extension" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
TARGET_DIR="$DATA_HOME/cachycaos/webapps/router-extension"
BACKUP_DIR="$DATA_HOME/cachycaos/webapps/backups"

die() {
  echo "Error: $*" >&2
  exit 1
}

validate_target() {
  [[ "$TARGET_DIR" == */cachycaos/webapps/router-extension ]] ||
    die "Ruta de instalación inesperada: $TARGET_DIR"
}

install_router() {
  local stamp backup

  command -v python3 >/dev/null 2>&1 ||
    die "Python 3 es necesario para validar el manifiesto."

  python3 -m json.tool "$SOURCE_DIR/manifest.json" >/dev/null

  if command -v node >/dev/null 2>&1; then
    node --check "$SOURCE_DIR/background.js"
    node --check "$SOURCE_DIR/popup.js"
    node --check "$SOURCE_DIR/router-core.mjs"
  fi

  if [[ -d "$TARGET_DIR" ]]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$BACKUP_DIR/router-extension-$stamp"
    mkdir -p "$BACKUP_DIR"
    cp -a "$TARGET_DIR" "$backup"
    echo "✓ Respaldo: $backup"
  fi

  mkdir -p "$TARGET_DIR"

  install -m 0644 "$SOURCE_DIR/manifest.json" "$TARGET_DIR/manifest.json"
  install -m 0644 "$SOURCE_DIR/background.js" "$TARGET_DIR/background.js"
  install -m 0644 "$SOURCE_DIR/router-core.mjs" "$TARGET_DIR/router-core.mjs"
  install -m 0644 "$SOURCE_DIR/popup.html" "$TARGET_DIR/popup.html"
  install -m 0644 "$SOURCE_DIR/popup.css" "$TARGET_DIR/popup.css"
  install -m 0644 "$SOURCE_DIR/popup.js" "$TARGET_DIR/popup.js"

  echo "✓ Prototipo instalado: $TARGET_DIR"
  echo
  echo "Carga esta carpeta desde vivaldi://extensions:"
  echo "  $TARGET_DIR"
}

uninstall_router() {
  validate_target

  if [[ ! -e "$TARGET_DIR" ]]; then
    echo "El prototipo no está instalado."
    return
  fi

  rm -rf -- "$TARGET_DIR"
  echo "✓ Archivos del prototipo eliminados."
  echo "  Retira también la extensión desde vivaldi://extensions."
}

case "${1:-install}" in
  install)
    install_router
    ;;
  path)
    printf '%s\n' "$TARGET_DIR"
    ;;
  uninstall)
    uninstall_router
    ;;
  *)
    die "Uso: $0 [install|path|uninstall]"
    ;;
esac
