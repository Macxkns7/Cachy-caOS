#!/usr/bin/env bash

set -euo pipefail

NEST="$HOME/.local/share/cachycaos/core/nest/nest.sh"

MODULE_DIR="$HOME/.local/share/cachycaos/modules/keybinds"
LIB_DIR="$MODULE_DIR/lib"
CACHE_DIR="$MODULE_DIR/cache"
REPORT_DIR="$MODULE_DIR/reports"
BACKUP_DIR="$MODULE_DIR/backups"

RUNTIME_FILE="$CACHE_DIR/runtime.tsv"
SOURCE_FILE="$CACHE_DIR/source.tsv"
ENRICHED_FILE="$CACHE_DIR/enriched.tsv"
CACHE_FILE="$ENRICHED_FILE"
REPORT_FILE="$REPORT_DIR/keybinds-report.txt"

SOURCE_SCANNER="$LIB_DIR/source-scanner.py"
BIND_RESOLVER="$LIB_DIR/bind-resolver.py"
KEYBIND_GENERATOR="$LIB_DIR/keybind-generator.py"
RUNTIME_SCANNER="$LIB_DIR/runtime-scanner.py"

[[ -f "$NEST" ]] || {
  echo "Error: No se encontró Nest UI en $NEST" >&2
  exit 1
}

source "$NEST"

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
}

run_generator() {
  python3 "$KEYBIND_GENERATOR" "$@"
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
    {
      identity = $11 "|" $2
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
  nest_header "Atajos de teclado" "v0.2 · Gestión segura"

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
      {
        identity = $11 "|" $2
        count[identity]++
        lines[identity] = lines[identity] sprintf("%-35s → %s%c", $2, $3, 10)
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

export_report() {
  {
    echo "Cachy-caOS · Atajos de teclado v0.2"
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
    nest_header "Cachy-caOS" "Atajos de teclado · v0.2"

    choice="$(
      nest_menu \
        "Resumen" \
        "Buscar atajos" \
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
