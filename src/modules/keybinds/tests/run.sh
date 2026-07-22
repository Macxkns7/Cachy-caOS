#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT/lib/keybind-generator.py"
EDITOR="$ROOT/lib/manifest-editor.py"
FIXTURE="$ROOT/tests/fixtures/binds-v2.toml"
TEMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP"
}

trap cleanup EXIT

python3 -m py_compile "$ROOT"/lib/*.py

chmod +x "$ROOT/tests/fixtures/hyprctl-runtime"

python3 "$ROOT/lib/runtime-scanner.py" \
  --hyprctl "$ROOT/tests/fixtures/hyprctl-runtime" \
  --output "$TEMP/runtime.tsv"

test "$(wc -l < "$TEMP/runtime.tsv")" -eq 3
grep -q $'SUPER + Q\t' "$TEMP/runtime.tsv"
grep -q $'SUPER + SUPER_L\t.*\trelease$' "$TEMP/runtime.tsv"
grep -q $'SUBIR VOLUMEN\t.*\tlocked,repeat$' "$TEMP/runtime.tsv"

python3 "$ROOT/lib/source-scanner.py" \
  --config "$ROOT/tests/fixtures/source-root.lua" \
  --output "$TEMP/source.tsv"

test "$(wc -l < "$TEMP/source.tsv")" -eq 2
awk -F '\t' 'NF != 7 { exit 1 }' "$TEMP/source.tsv"
grep -q $'SUPER + W\t.*managed.lua\t' "$TEMP/source.tsv"

python3 "$ROOT/lib/bind-resolver.py" \
  --runtime "$ROOT/tests/fixtures/runtime-source.tsv" \
  --source "$TEMP/source.tsv" \
  --output "$TEMP/enriched-source.tsv" \
  >/dev/null

awk -F '\t' 'NF != 12 { exit 1 }' "$TEMP/enriched-source.tsv"
grep -q $'SUPER + Q\t.*source-root.lua\t' "$TEMP/enriched-source.tsv"
grep -q $'SUPER + W\t.*managed.lua\t' "$TEMP/enriched-source.tsv"

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

cp "$ROOT/data/binds.toml" "$TEMP/editor.toml"
install -m 644 /dev/null "$TEMP/empty-inventory.tsv"

python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-external.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  import --identity external-return --id imported.terminal

test "$(python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-external.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  list | awk -F '\t' '$1 == "imported.terminal" { print $2 }')" = false

if python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-external.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  enable --id imported.terminal; then
  echo "Error: se permitió habilitar un atajo externo duplicado." >&2
  exit 1
fi

python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$TEMP/empty-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  enable --id imported.terminal

python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$TEMP/empty-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  set --id imported.terminal --action window.close

test "$(python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$TEMP/empty-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  list | awk -F '\t' '$1 == "imported.terminal" { print $7 }')" = -

python3 "$EDITOR" \
  --data "$TEMP/editor.toml" \
  --backups "$TEMP/editor-backups" \
  --inventory "$TEMP/empty-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  add --id workspace.next --combo "SUPER + J" \
  --category Workspaces --description "Siguiente workspace" \
  --action workspace.focus --argument "e+1" --enabled

python3 "$GENERATOR" \
  --data "$TEMP/editor.toml" \
  --build "$TEMP/editor.lua" \
  --target "$TEMP/editor-target.lua" \
  --backups "$TEMP/editor-backups" \
  --install

grep -q 'hl.dsp.focus({ workspace = "e+1" })' "$TEMP/editor.lua"
test "$(find "$TEMP/editor-backups" -name 'binds-*.toml' | wc -l)" -ge 4

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
