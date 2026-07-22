#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT/lib/keybind-generator.py"
FIXTURE="$ROOT/tests/fixtures/binds-v2.toml"
TEMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP"
}

trap cleanup EXIT

python3 -m py_compile "$ROOT"/lib/*.py

python3 "$GENERATOR" \
  --data "$FIXTURE" \
  --build "$TEMP/build.lua" \
  --target "$TEMP/target.lua" \
  --backups "$TEMP/backups" \
  --install

grep -q 'locked = true' "$TEMP/target.lua"
grep -q 'mouse = true' "$TEMP/target.lua"
grep -q 'release = true' "$TEMP/target.lua"
grep -q 'repeating = true' "$TEMP/target.lua"
grep -q 'repeating = false' "$TEMP/target.lua"

python3 "$GENERATOR" \
  --data "$FIXTURE" \
  --build "$TEMP/build.lua" \
  --target "$TEMP/target.lua" \
  --backups "$TEMP/backups" \
  --verify

printf '%s\n' '-- estado anterior válido' > "$TEMP/target.lua"
mkdir -p "$TEMP/bin"
cp "$ROOT/tests/fixtures/hyprctl-invalid" "$TEMP/bin/hyprctl"
chmod +x "$TEMP/bin/hyprctl"

if PATH="$TEMP/bin:$PATH" python3 "$GENERATOR" \
  --data "$FIXTURE" \
  --build "$TEMP/build.lua" \
  --target "$TEMP/target.lua" \
  --backups "$TEMP/backups" \
  --install --reload; then
  echo "Error: se esperaba un fallo de validación." >&2
  exit 1
fi

grep -qx -- '-- estado anterior válido' "$TEMP/target.lua"

echo "✓ Pruebas del módulo Keybinds completadas"
