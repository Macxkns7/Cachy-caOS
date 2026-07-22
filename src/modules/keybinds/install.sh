#!/usr/bin/env bash

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SOURCE/../.." && pwd)"
MODULE="$HOME/.local/share/cachycaos/modules/keybinds"
BIN="$HOME/.local/bin"

mkdir -p "$MODULE" "$BIN"

for directory in build data lib; do
  mkdir -p "$MODULE/$directory"
  cp -a "$SOURCE/$directory/." "$MODULE/$directory/"
done

chmod 755 "$MODULE"/lib/*.py

install -m 755 "$SOURCE/app.sh" "$MODULE/app.sh"
install -m 755 \
  "$SOURCE_ROOT/bin/cachycaos-keybinds" \
  "$BIN/cachycaos-keybinds"

echo "✓ Módulo instalado: $MODULE"
echo "✓ Comando instalado: $BIN/cachycaos-keybinds"
echo
echo "Comprueba que ~/.config/hypr/hyprland.lua contenga:"
echo '  require("cachycaos.keybinds")'
echo
echo "Vista previa: cachycaos-keybinds plan"
