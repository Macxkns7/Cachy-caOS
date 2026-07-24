#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT/lib/keybind-generator.py"
EDITOR="$ROOT/lib/manifest-editor.py"
FIXTURE="$ROOT/tests/fixtures/binds-v2.toml"
ACTION_FIXTURE="$ROOT/tests/fixtures/binds-actions.toml"
TEMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP"
}

trap cleanup EXIT

python3 -m py_compile "$ROOT"/lib/*.py

chmod +x "$ROOT/tests/fixtures/hyprctl-runtime"
chmod +x \
  "$ROOT/tests/fixtures/hyprctl-reconcile" \
  "$ROOT/tests/fixtures/playerctl-log"

python3 "$ROOT/lib/runtime-scanner.py" \
  --hyprctl "$ROOT/tests/fixtures/hyprctl-runtime" \
  --output "$TEMP/runtime.tsv"

test "$(wc -l < "$TEMP/runtime.tsv")" -eq 5
grep -q $'SUPER + Q\t' "$TEMP/runtime.tsv"
grep -q $'SUPER + SUPER_L\t.*\trelease$' "$TEMP/runtime.tsv"
grep -q $'SUBIR VOLUMEN\t.*\tlocked,repeat$' "$TEMP/runtime.tsv"
grep -q $'FINALIZAR LLAMADA\t.*\tlocked,long_press$' "$TEMP/runtime.tsv"
grep -q $'FINALIZAR LLAMADA\t.*\t-$' "$TEMP/runtime.tsv"

test "$(
  python3 "$EDITOR" \
    --data "$FIXTURE" \
    --backups "$TEMP/fixture-backups" \
    list | wc -l
)" -eq 5

python3 "$ROOT/lib/source-scanner.py" \
  --config "$ROOT/tests/fixtures/source-root.lua" \
  --output "$TEMP/source.tsv"

test "$(wc -l < "$TEMP/source.tsv")" -eq 4
awk -F '\t' 'NF != 8 { exit 1 }' "$TEMP/source.tsv"
grep -q $'SUPER + W\t.*managed.lua\t' "$TEMP/source.tsv"
grep -q $'XF86HANGUPPHONE\t.*playerctl previous\tlong_press\t' "$TEMP/source.tsv"

python3 "$ROOT/lib/bind-resolver.py" \
  --runtime "$ROOT/tests/fixtures/runtime-source.tsv" \
  --source "$TEMP/source.tsv" \
  --output "$TEMP/enriched-source.tsv" \
  >/dev/null

awk -F '\t' 'NF != 12 { exit 1 }' "$TEMP/enriched-source.tsv"
grep -q $'SUPER + Q\t.*source-root.lua\t' "$TEMP/enriched-source.tsv"
grep -q $'SUPER + W\t.*managed.lua\t' "$TEMP/enriched-source.tsv"
grep -q $'FINALIZAR LLAMADA\t.*Siguiente pista\texec\tplayerctl next\t' \
  "$TEMP/enriched-source.tsv"
grep -q $'FINALIZAR LLAMADA\t.*Pista anterior\texec\tplayerctl previous\t' \
  "$TEMP/enriched-source.tsv"

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
grep -q 'long_press = true' "$TEMP/target.lua"
test "$(grep -c 'XF86HangupPhone' "$TEMP/target.lua")" -eq 2

cp "$ROOT/data/binds.toml" "$TEMP/longpress-conflicts.toml"
printf '%s\n' \
  $'external-long\tFINALIZAR LLAMADA\tMultimedia\tPista anterior\texec\tplayerctl previous\t/tmp/user-hyprland.lua\t42\t__lua\t5\tglobal\tlong_press' \
  > "$TEMP/longpress-inventory.tsv"

python3 "$EDITOR" \
  --data "$TEMP/longpress-conflicts.toml" \
  --backups "$TEMP/longpress-backups" \
  --inventory "$TEMP/longpress-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  add --id media.hangup.next --combo "XF86HangupPhone" \
  --category Multimedia --description "Siguiente pista" \
  --action exec --argument "playerctl next" --event press --enabled

python3 "$EDITOR" \
  --data "$TEMP/longpress-conflicts.toml" \
  --backups "$TEMP/longpress-backups" \
  --inventory "$TEMP/longpress-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  check-conflicts

python3 "$EDITOR" \
  --data "$TEMP/longpress-conflicts.toml" \
  --backups "$TEMP/longpress-backups" \
  --inventory "$TEMP/longpress-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  add --id media.hangup.previous --combo "XF86HangupPhone" \
  --category Multimedia --description "Pista anterior" \
  --action exec --argument "playerctl previous" \
  --event long_press --enabled

if python3 "$EDITOR" \
  --data "$TEMP/longpress-conflicts.toml" \
  --backups "$TEMP/longpress-backups" \
  --inventory "$TEMP/longpress-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  check-conflicts; then
  echo "Error: no se detectó el conflicto long_press externo." >&2
  exit 1
fi

python3 "$GENERATOR" \
  --data "$ACTION_FIXTURE" \
  --build "$TEMP/actions.lua"

grep -q 'hl.dsp.exec_cmd("kitty")' "$TEMP/actions.lua"
grep -q \
  '/.local/share/cachycaos/modules/keybinds/helpers/nest-media-hangup")' \
  "$TEMP/actions.lua"
grep -q 'hl.dsp.window.close()' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.float({ action = "toggle" })' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.pseudo()' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.fullscreen({ action = "toggle" })' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.drag()' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.resize()' "$TEMP/actions.lua"
grep -q 'hl.dsp.layout("togglesplit")' "$TEMP/actions.lua"
grep -q 'hl.dsp.focus({ direction = "left" })' "$TEMP/actions.lua"
grep -q 'hl.dsp.focus({ workspace = "1" })' "$TEMP/actions.lua"
grep -q 'hl.dsp.workspace.toggle_special("magic")' "$TEMP/actions.lua"
grep -q 'hl.dsp.window.move({ workspace = "1" })' "$TEMP/actions.lua"

HELPER="$ROOT/helpers/nest-media-hangup"
PLAYERCTL_FIXTURE="$ROOT/tests/fixtures/playerctl-log"
chmod +x "$HELPER"

mkdir -p "$TEMP/single-runtime"
PLAYERCTL_LOG="$TEMP/single-playerctl.log" \
NEST_PLAYERCTL_BIN="$PLAYERCTL_FIXTURE" \
XDG_RUNTIME_DIR="$TEMP/single-runtime" \
  "$HELPER"
grep -qx 'next' "$TEMP/single-playerctl.log"

mkdir -p "$TEMP/double-runtime"
PLAYERCTL_LOG="$TEMP/double-playerctl.log" \
NEST_PLAYERCTL_BIN="$PLAYERCTL_FIXTURE" \
XDG_RUNTIME_DIR="$TEMP/double-runtime" \
  "$HELPER" &
first_tap_pid=$!
sleep 0.05
PLAYERCTL_LOG="$TEMP/double-playerctl.log" \
NEST_PLAYERCTL_BIN="$PLAYERCTL_FIXTURE" \
XDG_RUNTIME_DIR="$TEMP/double-runtime" \
  "$HELPER"
wait "$first_tap_pid"
grep -qx 'previous' "$TEMP/double-playerctl.log"
test "$(wc -l < "$TEMP/double-playerctl.log")" -eq 1

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

cp "$ROOT/data/binds.toml" "$TEMP/bulk.toml"
cp "$TEMP/bulk.toml" "$TEMP/bulk-before.toml"

bulk_preview="$(
  python3 "$EDITOR" \
    --data "$TEMP/bulk.toml" \
    --backups "$TEMP/bulk-backups" \
    --inventory "$ROOT/tests/fixtures/enriched-bulk.tsv" \
    --managed-target /tmp/managed-keybinds.lua \
    import-all --dry-run
)"

grep -q 'Atajos por importar: 3' <<<"$bulk_preview"
grep -q 'apps.super-return' <<<"$bulk_preview"
grep -q 'windows.super-c' <<<"$bulk_preview"
grep -q 'workspaces.super-2' <<<"$bulk_preview"
cmp -s "$TEMP/bulk.toml" "$TEMP/bulk-before.toml"
test ! -e "$TEMP/bulk-backups"

python3 "$EDITOR" \
  --data "$TEMP/bulk.toml" \
  --backups "$TEMP/bulk-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-bulk.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  import-all

test "$(
  python3 "$EDITOR" \
    --data "$TEMP/bulk.toml" \
    --backups "$TEMP/bulk-backups" \
    list | wc -l
)" -eq 4
test "$(
  python3 "$EDITOR" \
    --data "$TEMP/bulk.toml" \
    --backups "$TEMP/bulk-backups" \
    list | awk -F '\t' '$2 == "false" { count++ } END { print count + 0 }'
)" -eq 3

bulk_repeat="$(
  python3 "$EDITOR" \
    --data "$TEMP/bulk.toml" \
    --backups "$TEMP/bulk-backups" \
    --inventory "$ROOT/tests/fixtures/enriched-bulk.tsv" \
    --managed-target /tmp/managed-keybinds.lua \
    import-all
)"
grep -q 'Atajos importados: 0' <<<"$bulk_repeat"
test "$(find "$TEMP/bulk-backups" -name 'binds-*.toml' | wc -l)" -eq 1

cp "$TEMP/bulk.toml" "$TEMP/bulk-before-enable.toml"
if python3 "$EDITOR" \
  --data "$TEMP/bulk.toml" \
  --backups "$TEMP/bulk-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-bulk.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  enable-drafts; then
  echo "Error: se habilitó un lote con conflictos externos." >&2
  exit 1
fi
cmp -s "$TEMP/bulk.toml" "$TEMP/bulk-before-enable.toml"

python3 "$EDITOR" \
  --data "$TEMP/bulk.toml" \
  --backups "$TEMP/bulk-backups" \
  --inventory "$TEMP/empty-inventory.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  enable-drafts

test "$(
  python3 "$EDITOR" \
    --data "$TEMP/bulk.toml" \
    --backups "$TEMP/bulk-backups" \
    list | awk -F '\t' '$2 != "true" { count++ } END { print count + 0 }'
)" -eq 0

cp "$ROOT/data/binds.toml" "$TEMP/unsupported.toml"
cp "$TEMP/unsupported.toml" "$TEMP/unsupported-before.toml"
if python3 "$EDITOR" \
  --data "$TEMP/unsupported.toml" \
  --backups "$TEMP/unsupported-backups" \
  --inventory "$ROOT/tests/fixtures/enriched-unsupported.tsv" \
  --managed-target /tmp/managed-keybinds.lua \
  import-all; then
  echo "Error: se aceptó parcialmente una importación incompatible." >&2
  exit 1
fi
cmp -s "$TEMP/unsupported.toml" "$TEMP/unsupported-before.toml"
test ! -e "$TEMP/unsupported-backups"

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

cat > "$TEMP/old-managed.lua" <<'LUA'
hl.bind(
    "SUPER + X",
    hl.dsp.exec_cmd("old-command"),
    { description = "Anterior" }
)
return true
LUA

cp "$ROOT/tests/fixtures/hyprctl-reconcile" "$TEMP/bin/hyprctl"
chmod +x "$TEMP/bin/hyprctl"

HYPRCTL_LOG="$TEMP/hyprctl-eval.log" \
PATH="$TEMP/bin:$PATH" \
python3 "$GENERATOR" \
  --data "$FIXTURE" \
  --build "$TEMP/reconciled.lua" \
  --target "$TEMP/old-managed.lua" \
  --backups "$TEMP/reconcile-backups" \
  --install --reload

grep -q 'hl.unbind("SUPER + X")' "$TEMP/hyprctl-eval.log"
grep -q 'hl.unbind("XF86HangupPhone")' "$TEMP/hyprctl-eval.log"
grep -Fq 'package.loaded["cachycaos.keybinds"] = nil' \
  "$TEMP/hyprctl-eval.log"
grep -Fq 'require("cachycaos.keybinds")' "$TEMP/hyprctl-eval.log"

echo "✓ Pruebas del módulo Keybinds completadas"
