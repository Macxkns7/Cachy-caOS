#!/usr/bin/env bash

set -euo pipefail

NEST="$HOME/.local/share/cachycaos/core/nest/nest.sh"

[[ -f "$NEST" ]] || {
  echo "Error: No se encontró Nest UI."
  exit 1
}

source "$NEST"

APP_DIR="$HOME/.local/share/applications"
DATA_DIR="$HOME/.local/share/cachycaos/webapps"
ICON_DIR="$DATA_DIR/icons"

mkdir -p "$APP_DIR" "$ICON_DIR"

die() {
  echo "Error: $*" >&2
  exit 1
}

slugify() {
  printf '%s' "$1" |
    iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

url_host() {
  local url="${1:-}"
  local authority host

  [[ -n "$url" ]] || return 1

  authority="${url#*://}"
  authority="${authority%%/*}"
  authority="${authority##*@}"

  if [[ "$authority" == \[*\]* ]]; then
    host="${authority#\[}"
    host="${host%%\]*}"
  else
    host="${authority%%:*}"
  fi

  host="${host,,}"
  host="${host%.}"

  [[ -n "$host" ]] || return 1
  printf '%s\n' "$host"
}

vivaldi_startup_wm_class() {
  local url="${1:-}"
  local host

  host="$(url_host "$url")" ||
    die "No pude obtener el dominio de la URL: $url"

  printf 'vivaldi-%s__-Default\n' "$host"
}

find_browser() {
  if command -v vivaldi-stable >/dev/null 2>&1; then
    command -v vivaldi-stable
  elif command -v vivaldi >/dev/null 2>&1; then
    command -v vivaldi
  else
    die "No encontré Vivaldi instalado."
  fi
}

refresh_launchers() {
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

  if command -v noctalia >/dev/null 2>&1; then
    noctalia msg dock-reload >/dev/null 2>&1 || true
  fi
}

set_desktop_key() {
  local file="${1:-}"
  local key="${2:-}"
  local value="${3:-}"
  local tmp

  [[ -f "$file" ]] || die "No existe el archivo: $file"
  [[ -n "$key" ]] || die "Falta la clave del archivo .desktop."

  tmp="$(mktemp)"

  awk -v key="$key" -v value="$value" '
    BEGIN {
      written = 0
      prefix = key "="
    }

    index($0, prefix) == 1 {
      if (!written) {
        print prefix value
        written = 1
      }
      next
    }

    /^Terminal=/ && !written {
      print prefix value
      written = 1
    }

    {
      print
    }

    END {
      if (!written) {
        print prefix value
      }
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
  chmod +x "$file"
}

create_webapp() {
  local name="${1:-}"
  local url="${2:-}"
  local custom_icon="${3:-}"
  local slug desktop_file icon_path favicon_url browser startup_wm_class

  if [[ -z "$name" ]]; then
    name="$(gum input --prompt "Nombre › " --placeholder "ChatGPT")"
  fi
  [[ -n "$name" ]] || return 1

  if [[ -z "$url" ]]; then
    url="$(gum input --prompt "URL › " --placeholder "https://chatgpt.com")"
  fi
  [[ -n "$url" ]] || return 1

  if [[ ! "$url" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
    url="https://$url"
  fi

  slug="$(slugify "$name")"
  [[ -n "$slug" ]] || die "No pude generar un identificador válido."

  desktop_file="$APP_DIR/cachycaos-webapp-$slug.desktop"
  icon_path="$ICON_DIR/$slug.png"
  browser="$(find_browser)"
  startup_wm_class="$(vivaldi_startup_wm_class "$url")"

  if [[ -e "$desktop_file" ]]; then
    if ! gum confirm "La webapp ya existe. ¿Sobrescribirla?"; then
      return 0
    fi
  fi

  favicon_url="https://www.google.com/s2/favicons?domain_url=${url}&sz=256"

  if ! curl -fsSL "$favicon_url" -o "$icon_path" ||
     [[ ! -s "$icon_path" ]]; then
    rm -f "$icon_path"

    if [[ -z "$custom_icon" ]]; then
      custom_icon="$(gum input \
        --prompt "Icono › " \
        --placeholder "/ruta/icono.png o URL")"
    fi

    if [[ "$custom_icon" =~ ^https?:// ]]; then
      curl -fsSL "$custom_icon" -o "$icon_path" ||
        die "No pude descargar el icono."
    elif [[ -f "$custom_icon" ]]; then
      cp "$custom_icon" "$icon_path"
    else
      die "No se pudo obtener un icono válido."
    fi
  fi

  cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=Abrir $name como aplicación web
Exec=$HOME/.local/bin/cachycaos-webapp launch "$url"
Icon=$icon_path
StartupWMClass=$startup_wm_class
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
X-CachycaOS-WebApp=true
X-CachycaOS-WebApp-URL=$url
DESKTOP

  chmod +x "$desktop_file"
  desktop-file-validate "$desktop_file" || true
  refresh_launchers

  gum style \
    --border rounded \
    --padding "1 2" \
    "✓ WebApp creada" \
    "$name" \
    "$url" \
    "$startup_wm_class"
}

launch_webapp() {
  local url="${1:-}"
  local browser

  [[ -n "$url" ]] || die "Debes indicar una URL."
  browser="$(find_browser)"

  exec setsid "$browser" --app="$url"
}

list_webapps() {
  local found=false
  local file name url startup_wm_class

  for file in "$APP_DIR"/cachycaos-webapp-*.desktop; do
    [[ -e "$file" ]] || continue
    found=true

    name="$(sed -n 's/^Name=//p' "$file" | head -1)"
    url="$(sed -n 's/^X-CachycaOS-WebApp-URL=//p' "$file" | head -1)"
    startup_wm_class="$(sed -n 's/^StartupWMClass=//p' "$file" | head -1)"

    printf '• %s\n  %s\n  WMClass: %s\n' \
      "$name" \
      "$url" \
      "${startup_wm_class:-sin configurar}"
  done

  [[ "$found" == true ]] || echo "No hay WebApps instaladas."
}

repair_webapps() {
  local found=false
  local repaired=0
  local skipped=0
  local file name url startup_wm_class

  for file in "$APP_DIR"/cachycaos-webapp-*.desktop; do
    [[ -e "$file" ]] || continue
    found=true

    name="$(sed -n 's/^Name=//p' "$file" | head -1)"
    url="$(sed -n 's/^X-CachycaOS-WebApp-URL=//p' "$file" | head -1)"

    if [[ -z "$url" ]]; then
      printf '⚠ %s: no tiene X-CachycaOS-WebApp-URL\n' \
        "${name:-$(basename "$file")}"
      ((skipped += 1))
      continue
    fi

    startup_wm_class="$(vivaldi_startup_wm_class "$url")"
    set_desktop_key "$file" "StartupWMClass" "$startup_wm_class"

    desktop-file-validate "$file" >/dev/null 2>&1 || true

    printf '✓ %s → %s\n' \
      "${name:-$(basename "$file")}" \
      "$startup_wm_class"

    ((repaired += 1))
  done

  [[ "$found" == true ]] || die "No hay WebApps para reparar."

  refresh_launchers

  echo
  echo "WebApps reparadas: $repaired"
  echo "WebApps omitidas:  $skipped"
}

remove_webapp() {
  local files=()
  local labels=()
  local file name selected selected_file slug

  for file in "$APP_DIR"/cachycaos-webapp-*.desktop; do
    [[ -e "$file" ]] || continue
    files+=("$file")
    name="$(sed -n 's/^Name=//p' "$file" | head -1)"
    labels+=("$name")
  done

  ((${#files[@]} > 0)) || die "No hay WebApps para eliminar."

  selected="$(printf '%s\n' "${labels[@]}" |
    gum choose --header "Selecciona la WebApp que deseas eliminar")"

  [[ -n "$selected" ]] || exit 0

  for i in "${!labels[@]}"; do
    if [[ "${labels[$i]}" == "$selected" ]]; then
      selected_file="${files[$i]}"
      break
    fi
  done

  [[ -n "${selected_file:-}" ]] || die "No pude localizar la WebApp."

  slug="$(basename "$selected_file" .desktop)"
  slug="${slug#cachycaos-webapp-}"

  rm -f "$selected_file"
  rm -f "$ICON_DIR/$slug.png"

  refresh_launchers
  echo "✓ $selected eliminada."
}

create_webapp_tui() {
  local NAME URL ICON

  nest_clear
  nest_header "WebApps" "Nueva WebApp"

  NAME="$(gum input --placeholder "ChatGPT")"
  [[ -n "$NAME" ]] || return

  URL="$(gum input --placeholder "https://chatgpt.com")"
  [[ -n "$URL" ]] || return

  ICON="$(gum input --placeholder "Icono (opcional)")"

  echo

  if ! gum confirm "¿Crear '$NAME'?"; then
    return
  fi

  create_webapp "$NAME" "$URL" "$ICON"
}

main_menu() {
  local choice

  while true; do
    nest_clear
    nest_header "Cachy-caOS WebApps" "v0.6 Beta"

    choice="$(nest_menu \
      "Crear WebApp" \
      "Listar WebApps" \
      "Eliminar WebApp" \
      "Reparar WebApps" \
      "Salir")"

    case "$choice" in
      "Crear WebApp")
        create_webapp_tui
        read -r -p "Presiona Enter para continuar..."
        ;;

      "Listar WebApps")
        echo
        list_webapps
        echo
        read -r -p "Presiona Enter para continuar..."
        ;;

      "Eliminar WebApp")
        remove_webapp
        read -r -p "Presiona Enter para continuar..."
        ;;

      "Reparar WebApps")
        echo
        repair_webapps
        echo
        nest_success "WebApps y launchers actualizados."
        read -r -p "Presiona Enter para continuar..."
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
  cachycaos-webapp create
  cachycaos-webapp list
  cachycaos-webapp remove
  cachycaos-webapp repair
  cachycaos-webapp launch URL
HELP
}

case "${1:-}" in
  create)
    create_webapp
    ;;
  list)
    list_webapps
    ;;
  remove)
    remove_webapp
    ;;
  repair)
    repair_webapps
    ;;
  launch)
    shift
    launch_webapp "${1:-}"
    ;;
  "")
    main_menu
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    die "Comando desconocido: $1"
    ;;
esac
