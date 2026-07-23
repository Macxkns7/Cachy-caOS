#!/usr/bin/env bash

set -euo pipefail

NEST="$HOME/.local/share/cachycaos/core/nest/nest.sh"

MODULE_DIR="$HOME/.local/share/cachycaos/modules/keybinds"
LIB_DIR="$MODULE_DIR/lib"
CACHE_DIR="$MODULE_DIR/cache"
REPORT_DIR="$MODULE_DIR/reports"
BACKUP_DIR="$MODULE_DIR/backups"
DATA_FILE="$MODULE_DIR/data/binds.toml"
MANAGED_TARGET="$HOME/.config/hypr/cachycaos/keybinds.lua"

RUNTIME_FILE="$CACHE_DIR/runtime.tsv"
SOURCE_FILE="$CACHE_DIR/source.tsv"
ENRICHED_FILE="$CACHE_DIR/enriched.tsv"
CACHE_FILE="$ENRICHED_FILE"
REPORT_FILE="$REPORT_DIR/keybinds-report.txt"

SOURCE_SCANNER="$LIB_DIR/source-scanner.py"
BIND_RESOLVER="$LIB_DIR/bind-resolver.py"
KEYBIND_GENERATOR="$LIB_DIR/keybind-generator.py"
RUNTIME_SCANNER="$LIB_DIR/runtime-scanner.py"
MANIFEST_EDITOR="$LIB_DIR/manifest-editor.py"

[[ -f "$NEST" ]] || {
  echo "Error: No se encontró Nest UI en $NEST" >&2
  exit 1
}

source "$NEST"

if ! declare -F nest_warning >/dev/null; then
  nest_warning() {
    local message="$*"

    if command -v gum >/dev/null 2>&1; then
      gum style \
        --border rounded \
        --border-foreground 214 \
        --foreground 214 \
        --padding "0 1" \
        "⚠ Atención" \
        "$message" || true
    else
      printf '⚠ %s\n' "$message"
    fi

    return 0
  }
fi

die() {
  nest_error "$*"
  exit 1
}

pause_screen() {
  echo
  read -r -p "Presiona Enter para continuar..."
}

check_dependencies() {
  local missing=()
  local command_name

  for command_name in gum hyprctl python3; do
    command -v "$command_name" >/dev/null 2>&1 ||
      missing+=("$command_name")
  done

  ((${#missing[@]} == 0)) ||
    die "Faltan dependencias: ${missing[*]}"

  [[ -x "$MANIFEST_EDITOR" ]] ||
    die "No se encontró el editor de manifiesto: $MANIFEST_EDITOR"
}

run_generator() {
  python3 "$KEYBIND_GENERATOR" "$@"
}

run_editor() {
  python3 "$MANIFEST_EDITOR" \
    --data "$DATA_FILE" \
    --backups "$BACKUP_DIR" \
    --inventory "$ENRICHED_FILE" \
    --managed-target "$MANAGED_TARGET" \
    "$@"
}

plan_changes() {
  nest_clear
  nest_header "Atajos de teclado" "Plan de cambios"
  run_generator --plan
  pause_screen
}

verify_managed_file() {
  nest_clear
  nest_header "Atajos de teclado" "Verificación"
  run_generator --verify
  pause_screen
}

apply_changes() {
  local conflicts

  refresh_runtime
  conflicts="$(duplicate_count)"

  if ((conflicts > 0)); then
    die "Hay $conflicts combinaciones duplicadas. Revísalas antes de aplicar."
  fi

  if ! run_editor check-conflicts; then
    die "El manifiesto se solapa con atajos externos. Corrige el conflicto antes de aplicar."
  fi

  nest_clear
  nest_header "Atajos de teclado" "Aplicar cambios"
  run_generator --plan
  echo

  gum confirm \
    "¿Instalar el archivo administrado y recargar Hyprland?" || {
      nest_warning "Operación cancelada; no se modificó nada."
      pause_screen
      return 0
    }

  run_generator --install --reload
  refresh_runtime
  nest_success "Atajos aplicados y verificados."
  pause_screen
}

rollback_changes() {
  nest_clear
  nest_header "Atajos de teclado" "Restaurar respaldo"

  gum confirm \
    "¿Restaurar el último respaldo y recargar Hyprland?" || {
      nest_warning "Operación cancelada; no se modificó nada."
      pause_screen
      return 0
    }

  run_generator --rollback --reload
  refresh_runtime
  nest_success "Último respaldo restaurado y verificado."
  pause_screen
}

refresh_runtime() {
  mkdir -p "$CACHE_DIR" "$REPORT_DIR" "$BACKUP_DIR"

  "$RUNTIME_SCANNER" --output "$RUNTIME_FILE" ||
    die "No pude consultar los atajos activos de Hyprland."

  "$SOURCE_SCANNER" --output "$SOURCE_FILE"

  "$BIND_RESOLVER" \
    --runtime "$RUNTIME_FILE" \
    --source "$SOURCE_FILE" \
    --output "$ENRICHED_FILE" \
    >/dev/null
}

total_count() {
  wc -l < "$CACHE_FILE" | tr -d ' '
}

without_description_count() {
  awk -F '\t' '$4 == "" { count++ } END { print count + 0 }' \
    "$CACHE_FILE"
}

duplicate_count() {
  awk -F '\t' '
    function binding_event(flags, item_count, items, index) {
      item_count = split(flags, items, ",")

      for (index = 1; index <= item_count; index++) {
        if (items[index] == "long_press")
          return "long_press"
        if (items[index] == "release")
          return "release"
        if (items[index] == "repeat")
          return "repeat"
      }

      return "press"
    }

    {
      identity = $11 "|" $2 "|" binding_event($12)
      count[identity]++
    }
    END {
      duplicates = 0

      for (identity in count) {
        if (count[identity] > 1) {
          duplicates++
        }
      }

      print duplicates
    }
  ' "$CACHE_FILE"
}

submap_count() {
  cut -f7 "$CACHE_FILE" |
    sort -u |
    sed '/^$/d' |
    wc -l |
    tr -d ' '
}

render_records() {
  awk -F '\t' '
    {
      printf "%-35s → %s\n", $2, $4
    }
  ' "$CACHE_FILE"
}

show_summary() {
  nest_clear
  nest_header "Atajos de teclado" "v0.4 · Migración segura"

  gum style \
    --border rounded \
    --padding "1 2" \
    "Estado general" \
    "" \
    "✓ $(total_count) atajos activos" \
    "◇ $(without_description_count) sin descripción" \
    "⚠ $(duplicate_count) combinaciones duplicadas" \
    "◆ $(submap_count) submaps detectados" \
    "" \
    "Compositor: Hyprland" \
    "Fuente: configuración activa"

  pause_screen
}

show_details_by_display() {
  local selected="$1"
  local combo record
  local identity action description dispatcher argument submap flags

  combo="${selected%% → *}"
  combo="$(sed 's/[[:space:]]*$//' <<<"$combo")"

  record="$(
    awk -F '\t' -v combo="$combo" '
      $2 == combo {
        print
        exit
      }
    ' "$CACHE_FILE"
  )"

  [[ -n "$record" ]] || return 0

  local category action_type origin source_line
  local runtime_dispatcher runtime_argument

  IFS=$'\t' read -r \
    identity combo category description action_type argument \
    origin source_line runtime_dispatcher runtime_argument submap flags \
    <<<"$record"

  nest_clear
  nest_header "Atajos de teclado" "Detalle"

  gum style \
    --border rounded \
    --padding "1 2" \
    "$combo" \
    "" \
    "$description" \
    "" \
    "Categoría: ${category:-Sin clasificar}" \
    "Estado: Activo" \
    "Origen: ${origin:-Hyprland}" \
    "Contexto: ${submap:-global}" \
    "" \
    "Detalles técnicos" \
    "Acción: ${action_type:-desconocida}" \
    "Argumento: ${argument:-ninguno}" \
    "Dispatcher runtime: ${runtime_dispatcher:-desconocido}" \
    "Línea fuente: ${source_line:-no disponible}" \
    "Flags: $flags" \
    "ID: ${identity:0:16}…"

  if [[ "$origin" == "$MANAGED_TARGET" ]]; then
    pause_screen
    return 0
  fi

  local choice identifier output
  choice="$(nest_menu "Importar como borrador" "Volver")" || true

  [[ "$choice" == "Importar como borrador" ]] || return 0

  identifier="$(
    gum input \
      --placeholder "ID único: por ejemplo, app.terminal"
  )" || true

  [[ -n "$identifier" ]] || return 0

  if output="$(run_editor import --identity "$identity" --id "$identifier" 2>&1)"; then
    nest_success "Atajo importado como borrador deshabilitado."
    printf '%s\n' "$output"
    echo
    echo "Puedes revisarlo en 'Atajos administrados'."
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

show_all() {
  local selected

  selected="$(
    render_records |
      gum filter \
        --placeholder "Escribe una tecla o una acción..." \
        --header "Buscar atajos"
  )" || true

  [[ -n "$selected" ]] || return 0
  show_details_by_display "$selected"
}

show_without_description() {
  local selected

  selected="$(
    awk -F '\t' '
      $4 == "" {
        printf "%-35s → %s\n", $2, $4
      }
    ' "$CACHE_FILE" |
      gum filter \
        --placeholder "Buscar..." \
        --header "Atajos sin descripción"
  )" || true

  [[ -n "$selected" ]] || return 0
  show_details_by_display "$selected"
}

show_duplicates() {
  local duplicates

  duplicates="$(
    awk -F '\t' '
      function binding_event(flags, item_count, items, index) {
        item_count = split(flags, items, ",")

        for (index = 1; index <= item_count; index++) {
          if (items[index] == "long_press")
            return "long_press"
          if (items[index] == "release")
            return "release"
          if (items[index] == "repeat")
            return "repeat"
        }

        return "press"
      }

      {
        identity = $11 "|" $2 "|" binding_event($12)
        count[identity]++
        lines[identity] = lines[identity] sprintf(
          "%-35s [%s] → %s%c",
          $2,
          binding_event($12),
          $3,
          10
        )
      }
      END {
        for (identity in count) {
          if (count[identity] > 1) {
            print "── " identity " ──"
            printf "%s", lines[identity]
            print ""
          }
        }
      }
    ' "$CACHE_FILE"
  )"

  nest_clear
  nest_header "Atajos de teclado" "Conflictos"

  if [[ -z "$duplicates" ]]; then
    nest_success "No se detectaron combinaciones duplicadas."
  else
    printf '%s\n' "$duplicates"
  fi

  pause_screen
}

render_managed_records() {
  run_editor list |
    awk -F '\t' '
      {
        state = $2 == "true" ? "activo" : "borrador"
        printf "%-24s · %-9s · %s → %s\n", $1, state, $3, $5
      }
    '
}

managed_draft_count() {
  run_editor list |
    awk -F '\t' '$2 == "false" { count++ } END { print count + 0 }'
}

import_external_drafts() {
  local preview output

  refresh_runtime
  nest_clear
  nest_header "Atajos de teclado" "Importación masiva"

  if ! preview="$(run_editor import-all --dry-run 2>&1)"; then
    nest_warning "$preview" || true
    pause_screen
    return 0
  fi

  printf '%s\n' "$preview"

  if grep -q 'Atajos por importar: 0' <<<"$preview"; then
    nest_success "No hay atajos externos nuevos por importar."
    pause_screen
    return 0
  fi

  echo
  gum confirm \
    "¿Crear todos estos registros como borradores deshabilitados?" || {
      nest_warning "Operación cancelada; no se modificó nada." || true
      pause_screen
      return 0
    }

  if output="$(run_editor import-all 2>&1)"; then
    nest_success "Importación completada como una sola transacción."
    printf '%s\n' "$output"
    echo
    echo "Los atajos siguen activos desde su origen y los nuevos registros"
    echo "permanecen deshabilitados hasta completar la migración."
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

enable_all_drafts() {
  local count output

  refresh_runtime
  count="$(managed_draft_count)"

  nest_clear
  nest_header "Atajos de teclado" "Habilitar borradores"

  if ((count == 0)); then
    nest_success "No hay borradores deshabilitados."
    pause_screen
    return 0
  fi

  gum style \
    --border rounded \
    --padding "1 2" \
    "Borradores preparados: $count" \
    "" \
    "N.E.S.T. comprobará el lote completo antes de escribir." \
    "Si una combinación sigue activa fuera del módulo," \
    "ningún registro será habilitado."

  echo
  gum confirm "¿Comprobar y habilitar los $count borradores?" || {
    nest_warning "Operación cancelada; no se modificó nada." || true
    pause_screen
    return 0
  }

  if output="$(run_editor enable-drafts 2>&1)"; then
    nest_success "Todos los borradores quedaron habilitados."
    printf '%s\n' "$output"
    echo
    echo "Revisa 'Planificar cambios' antes de aplicar."
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

choose_action() {
  local current="${1:-}"
  local actions=(
    exec
    window.close
    window.float.toggle
    window.pseudo
    window.fullscreen
    window.drag
    window.resize
    layout
    focus
    workspace.focus
    workspace.special
    window.move
  )
  local ordered=()
  local action

  [[ -z "$current" ]] || ordered+=("$current")

  for action in "${actions[@]}"; do
    [[ "$action" == "$current" ]] || ordered+=("$action")
  done

  gum choose "${ordered[@]}" --header "Acción administrada"
}

action_needs_argument() {
  case "$1" in
    exec|layout|focus|workspace.focus|workspace.special|window.move)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

add_managed_draft() {
  local identifier combo category description action argument event output

  nest_clear
  nest_header "Atajos de teclado" "Nuevo borrador"

  identifier="$(gum input --placeholder "ID: app.terminal")" || true
  [[ -n "$identifier" ]] || return 0

  combo="$(gum input --placeholder "Combinación: SUPER + Return")" || true
  [[ -n "$combo" ]] || return 0

  category="$(gum input --value "General" --placeholder "Categoría")" || true
  [[ -n "$category" ]] || return 0

  description="$(gum input --placeholder "Descripción visible")" || true
  [[ -n "$description" ]] || return 0

  action="$(choose_action)" || true
  [[ -n "$action" ]] || return 0

  event="$(
    gum choose \
      press \
      release \
      repeat \
      long_press \
      --header "Evento"
  )" || true
  [[ -n "$event" ]] || return 0

  argument=""
  if action_needs_argument "$action"; then
    argument="$(gum input --placeholder "Argumento o comando")" || true
    [[ -n "$argument" ]] || return 0
  fi

  local arguments=(
    add
    --id "$identifier"
    --combo "$combo"
    --category "$category"
    --description "$description"
    --action "$action"
    --event "$event"
  )
  [[ -z "$argument" ]] || arguments+=(--argument "$argument")

  if output="$(run_editor "${arguments[@]}" 2>&1)"; then
    nest_success "Borrador creado y deshabilitado por seguridad."
    printf '%s\n' "$output"
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

edit_managed_record() {
  local identifier="$1"
  local row enabled combo category description action argument event
  local locked mouse imported_from imported_line imported_identity
  local new_combo new_category new_description new_action new_argument output

  row="$(run_editor list | awk -F '\t' -v id="$identifier" '$1 == id { print; exit }')"
  [[ -n "$row" ]] || return 0

  IFS=$'\t' read -r \
    identifier enabled combo category description action argument event \
    locked mouse imported_from imported_line imported_identity <<<"$row"
  [[ "$argument" == "-" ]] && argument=""

  new_combo="$(gum input --value "$combo" --placeholder "Combinación")" || true
  [[ -n "$new_combo" ]] || return 0

  new_category="$(gum input --value "$category" --placeholder "Categoría")" || true
  [[ -n "$new_category" ]] || return 0

  new_description="$(gum input --value "$description" --placeholder "Descripción")" || true
  [[ -n "$new_description" ]] || return 0

  new_action="$(choose_action "$action")" || true
  [[ -n "$new_action" ]] || return 0

  new_argument=""
  if action_needs_argument "$new_action"; then
    new_argument="$(
      gum input --value "$argument" --placeholder "Argumento o comando"
    )" || true
    [[ -n "$new_argument" ]] || return 0
  fi

  local arguments=(
    set
    --id "$identifier"
    --combo "$new_combo"
    --category "$new_category"
    --description "$new_description"
    --action "$new_action"
  )
  [[ -z "$new_argument" ]] || arguments+=(--argument "$new_argument")

  if output="$(run_editor "${arguments[@]}" 2>&1)"; then
    nest_success "Borrador actualizado."
    printf '%s\n' "$output"
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

toggle_managed_boolean() {
  local identifier="$1"
  local field="$2"
  local current="$3"
  local next="true"
  local output

  [[ "$current" == "true" ]] && next="false"

  if output="$(run_editor set --id "$identifier" --"$field" "$next" 2>&1)"; then
    nest_success "Propiedad '$field' actualizada a $next."
    printf '%s\n' "$output"
  else
    nest_warning "$output" || true
  fi

  pause_screen
}

show_managed_record() {
  local identifier="$1"
  local row enabled combo category description action argument event
  local locked mouse imported_from imported_line imported_identity
  local state source choice output next_command

  while true; do
    row="$(run_editor list | awk -F '\t' -v id="$identifier" '$1 == id { print; exit }')"
    [[ -n "$row" ]] || return 0

    IFS=$'\t' read -r \
      identifier enabled combo category description action argument event \
      locked mouse imported_from imported_line imported_identity <<<"$row"
    [[ "$argument" == "-" ]] && argument=""

    state="Borrador deshabilitado"
    [[ "$enabled" == "true" ]] && state="Habilitado en el manifiesto"
    source="$imported_from"
    [[ "$source" == "managed" ]] && source="Creado en N.E.S.T."

    nest_clear
    nest_header "Atajos de teclado" "Administrado · $identifier"

    gum style \
      --border rounded \
      --padding "1 2" \
      "$combo" \
      "" \
      "$description" \
      "" \
      "Estado: $state" \
      "Categoría: $category" \
      "Acción: $action" \
      "Argumento: ${argument:-ninguno}" \
      "Evento: $event" \
      "Bloqueo: $locked" \
      "Ratón: $mouse" \
      "Origen: $source"

    next_command="Habilitar"
    [[ "$enabled" == "true" ]] && next_command="Deshabilitar"

    choice="$(
      nest_menu \
        "Editar datos" \
        "Cambiar evento" \
        "Alternar uso con sesión bloqueada" \
        "Alternar binding de ratón" \
        "$next_command" \
        "Eliminar del manifiesto" \
        "Volver"
    )" || true

    case "$choice" in
      "Editar datos")
        edit_managed_record "$identifier"
        ;;
      "Cambiar evento")
        local new_event
        new_event="$(
          gum choose \
            "$event" \
            press \
            release \
            repeat \
            long_press \
            --header "Evento"
        )" || true
        [[ -n "$new_event" ]] || continue
        run_editor set --id "$identifier" --event "$new_event"
        ;;
      "Alternar uso con sesión bloqueada")
        toggle_managed_boolean "$identifier" locked "$locked"
        ;;
      "Alternar binding de ratón")
        toggle_managed_boolean "$identifier" mouse "$mouse"
        ;;
      "Habilitar"|"Deshabilitar")
        next_command="enable"
        [[ "$choice" == "Deshabilitar" ]] && next_command="disable"
        if output="$(run_editor "$next_command" --id "$identifier" 2>&1)"; then
          nest_success "$choice completado en el manifiesto."
          printf '%s\n' "$output"
          echo
          echo "Usa 'Planificar cambios' antes de aplicar."
        else
          nest_warning "$output" || true
        fi
        pause_screen
        ;;
      "Eliminar del manifiesto")
        gum confirm \
          "¿Eliminar '$identifier'? El respaldo permitirá recuperarlo." || continue
        if output="$(run_editor remove --id "$identifier" 2>&1)"; then
          nest_success "Registro eliminado del manifiesto."
          printf '%s\n' "$output"
        else
          nest_warning "$output" || true
        fi
        pause_screen
        return 0
        ;;
      "Volver"|"")
        return 0
        ;;
    esac
  done
}

show_managed() {
  local choice selected identifier

  while true; do
    nest_clear
    nest_header "Atajos de teclado" "Administrados y borradores"

    choice="$(
      nest_menu \
        "Importar externos compatibles" \
        "Habilitar todos los borradores" \
        "Nuevo borrador" \
        "Abrir registro" \
        "Volver"
    )" || true

    case "$choice" in
      "Importar externos compatibles")
        import_external_drafts
        ;;
      "Habilitar todos los borradores")
        enable_all_drafts
        ;;
      "Nuevo borrador")
        add_managed_draft
        ;;
      "Abrir registro")
        selected="$(
          render_managed_records |
            gum filter \
              --placeholder "Buscar ID, combinación o descripción..." \
              --header "Manifiesto administrado"
        )" || true
        [[ -n "$selected" ]] || continue
        identifier="${selected%% · *}"
        identifier="$(sed 's/[[:space:]]*$//' <<<"$identifier")"
        show_managed_record "$identifier"
        ;;
      "Volver"|"")
        return 0
        ;;
    esac
  done
}

export_report() {
  {
    echo "Cachy-caOS · Atajos de teclado v0.4"
    echo "Generado: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "Atajos activos: $(total_count)"
    echo "Sin descripción: $(without_description_count)"
    echo "Combinaciones duplicadas: $(duplicate_count)"
    echo "Submaps detectados: $(submap_count)"
    echo
    render_records
  } > "$REPORT_FILE"
}

export_report_interactive() {
  export_report
  nest_success "Informe guardado en:"
  echo "$REPORT_FILE"
  pause_screen
}

main_menu() {
  local choice

  check_dependencies
  refresh_runtime

  while true; do
    nest_clear
    nest_header "Cachy-caOS" "Atajos de teclado · v0.4"

    choice="$(
      nest_menu \
        "Resumen" \
        "Buscar atajos" \
        "Atajos administrados" \
        "Sin descripción" \
        "Conflictos" \
        "Planificar cambios" \
        "Aplicar cambios" \
        "Verificar archivo administrado" \
        "Restaurar último respaldo" \
        "Actualizar" \
        "Exportar informe" \
        "Salir"
    )" || true

    case "$choice" in
      "Resumen")
        show_summary
        ;;
      "Buscar atajos")
        show_all
        ;;
      "Atajos administrados")
        show_managed
        ;;
      "Sin descripción")
        show_without_description
        ;;
      "Conflictos")
        show_duplicates
        ;;
      "Planificar cambios")
        plan_changes
        ;;
      "Aplicar cambios")
        apply_changes
        ;;
      "Verificar archivo administrado")
        verify_managed_file
        ;;
      "Restaurar último respaldo")
        rollback_changes
        ;;
      "Actualizar")
        refresh_runtime
        nest_success "Inventario actualizado."
        sleep 1
        ;;
      "Exportar informe")
        export_report_interactive
        ;;
      "Salir"|"")
        nest_goodbye
        break
        ;;
    esac
  done
}

show_help() {
  cat <<HELP
Uso:
  cachycaos-keybinds
  cachycaos-keybinds refresh
  cachycaos-keybinds report
  cachycaos-keybinds plan
  cachycaos-keybinds apply
  cachycaos-keybinds verify
  cachycaos-keybinds rollback [respaldo]
  cachycaos-keybinds --help
HELP
}

case "${1:-}" in
  "")
    main_menu
    ;;
  refresh)
    check_dependencies
    refresh_runtime
    echo "Inventario actualizado: $CACHE_FILE"
    ;;
  report)
    check_dependencies
    refresh_runtime
    export_report
    echo "Informe guardado: $REPORT_FILE"
    ;;
  plan)
    check_dependencies
    run_generator --plan
    ;;
  apply)
    check_dependencies
    refresh_runtime

    if (("$(duplicate_count)" > 0)); then
      die "Existen combinaciones duplicadas; aplicación bloqueada."
    fi

    if ! run_editor check-conflicts; then
      die "El manifiesto se solapa con atajos externos; aplicación bloqueada."
    fi

    run_generator --install --reload
    ;;
  verify)
    check_dependencies
    run_generator --verify
    ;;
  rollback)
    check_dependencies

    if [[ -n "${2:-}" ]]; then
      run_generator --rollback "$2" --reload
    else
      run_generator --rollback --reload
    fi
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    die "Comando desconocido: $1"
    ;;
esac
