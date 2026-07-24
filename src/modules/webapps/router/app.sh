#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_EXTENSION="$MODULE_DIR/extension"
REGISTRY_GENERATOR="$MODULE_DIR/lib/registry.py"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPLICATIONS_DIR="$DATA_HOME/applications"
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

validate_sources() {
  command -v python3 >/dev/null 2>&1 ||
    die "Python 3 es necesario para generar el registro."

  python3 -m json.tool "$SOURCE_EXTENSION/manifest.json" >/dev/null

  if command -v node >/dev/null 2>&1; then
    node --check "$SOURCE_EXTENSION/background.js"
    node --check "$SOURCE_EXTENSION/popup.js"
    node --check "$SOURCE_EXTENSION/router-core.mjs"
  fi
}

sync_router() {
  local quiet=false
  local result state count

  if [[ "${1:-}" == "--quiet" ]]; then
    quiet=true
  fi

  [[ -d "$TARGET_DIR" ]] ||
    die "El WebApp Router aún no está instalado."

  result="$(python3 "$REGISTRY_GENERATOR" \
    --applications "$APPLICATIONS_DIR" \
    --manifest-template "$SOURCE_EXTENSION/manifest.json" \
    --output "$TARGET_DIR")"

  IFS=$'\t' read -r state count <<< "$result"

  if [[ "$quiet" == true ]]; then
    printf '%s\t%s\n' "$state" "$count"
    return
  fi

  if [[ "$state" == "changed" ]]; then
    echo "✓ Registro actualizado: $count WebApp(s)"
    echo "  Recarga N.E.S.T. WebApp Router en vivaldi://extensions."
  else
    echo "✓ Registro al día: $count WebApp(s)"
  fi
}

install_router() {
  local stamp backup

  validate_sources

  if [[ -d "$TARGET_DIR" ]]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$BACKUP_DIR/router-extension-$stamp"
    mkdir -p "$BACKUP_DIR"
    cp -a "$TARGET_DIR" "$backup"
    echo "✓ Respaldo: $backup"
  fi

  mkdir -p "$TARGET_DIR"

  install -m 0644 "$SOURCE_EXTENSION/background.js" \
    "$TARGET_DIR/background.js"
  install -m 0644 "$SOURCE_EXTENSION/router-core.mjs" \
    "$TARGET_DIR/router-core.mjs"
  install -m 0644 "$SOURCE_EXTENSION/popup.html" \
    "$TARGET_DIR/popup.html"
  install -m 0644 "$SOURCE_EXTENSION/popup.css" \
    "$TARGET_DIR/popup.css"
  install -m 0644 "$SOURCE_EXTENSION/popup.js" \
    "$TARGET_DIR/popup.js"

  sync_router

  echo
  echo "✓ WebApp Router instalado: $TARGET_DIR"
  echo
  echo "Carga o recarga esta carpeta desde vivaldi://extensions:"
  echo "  $TARGET_DIR"
}

uninstall_router() {
  validate_target

  if [[ ! -e "$TARGET_DIR" ]]; then
    echo "El WebApp Router no está instalado."
    return
  fi

  rm -rf -- "$TARGET_DIR"
  echo "✓ Archivos del WebApp Router eliminados."
  echo "  Retira también la extensión desde vivaldi://extensions."
}

case "${1:-}" in
  install)
    install_router
    ;;
  sync)
    sync_router "${2:-}"
    ;;
  path)
    printf '%s\n' "$TARGET_DIR"
    ;;
  uninstall)
    uninstall_router
    ;;
  *)
    die "Uso: cachycaos-webapp-router {install|sync|path|uninstall}"
    ;;
esac
