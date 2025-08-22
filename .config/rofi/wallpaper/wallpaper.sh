#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/common.sh"

readonly WALLPAPERS_DIR="$HOME/Wallpapers"
readonly CURRENT_WALLPAPER="$CACHE_DIR/wallpaper/current"
readonly WALLPAPER_THEME_FILE="$HOME/.config/rofi/wallpaper/wallpaper.rasi"

mapfile -t WALL_LIST < <(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" \) | sort)
[ ${#WALL_LIST[@]} -eq 0 ] && {
  echo "No wallpapers found in directory: $WALLPAPERS_DIR"
  exit 1
}

set_wall() {
  local wall="$1"
  [ ! -f "$wall" ] && {
    echo "File not found: $wall"
    exit 1
  }
  local current="$(readlink -f "$CURRENT_WALLPAPER" 2>/dev/null || true)"
  if [[ "$current" != "$wall" ]]; then
    ensure_symlink "$wall" "$CURRENT_WALLPAPER"
    apply_colorscheme "$wall"
  fi
  ensure_command swww
  swww img "$wall"
}

get_current_index() {
  local cur="$(basename "$(readlink -f "$CURRENT_WALLPAPER" 2>/dev/null || echo "")")"
  for i in "${!WALL_LIST[@]}"; do
    [[ "$(basename "${WALL_LIST[$i]}")" == "$cur" ]] && echo "$i" && return
  done
  echo 0
}

next_wall() {
  local idx=$(get_current_index)
  set_wall "${WALL_LIST[$(((idx + 1) % ${#WALL_LIST[@]}))]}"
}

prev_wall() {
  local idx=$(get_current_index)
  set_wall "${WALL_LIST[$(((idx - 1 + ${#WALL_LIST[@]}) % ${#WALL_LIST[@]}))]}"
}

random_wall() {
  local current="$(readlink -f "$CURRENT_WALLPAPER" 2>/dev/null || true)"
  local idx next

  [ "${#WALL_LIST[@]}" -le 1 ] && {
    set_wall "${WALL_LIST[0]}"
    return
  }

  while :; do
    idx=$((RANDOM % ${#WALL_LIST[@]}))
    next="${WALL_LIST[$idx]}"
    [[ "$next" != "$current" ]] && break
  done

  set_wall "$next"
}

select_wall() {
  local choice #"$WALLPAPER_THEME_FILE"
  choice=$(printf '%s\n' "${WALL_LIST[@]}" | rofi -dmenu -theme)
  if [ -n "$choice" ]; then
    if [ -f "$choice" ]; then
      set_wall "$choice"
    else
      echo "Selected file does not exist: $choice" >&2
      return 1
    fi
  fi
}

main() {
  case "${1-}" in
  -n | --next) next_wall ;;
  -p | --prev) prev_wall ;;
  -r | --random) random_wall ;;
  -s | --set) set_wall "${2:?Error: Please provide a wallpaper file path}" ;;
  -S | --select) select_wall ;;
  -c | --current) readlink -f "$CURRENT_WALLPAPER" ;;
  -h | --help | *) echo "Uso: $0 [ --next | --prev | --random | --set <wallpaper> | --select | --current ]" ;;
  esac
}

main "$@"
