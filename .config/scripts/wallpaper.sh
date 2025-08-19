#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache"
WALL_DIR="$HOME/Wallpapers"
WALL_CACHE_DIR="$CACHE_DIR/wallpaper"
mkdir -p "$WALL_CACHE_DIR"

CURRENT_WALL="$WALL_CACHE_DIR/current"

mapfile -t WALL_LIST < <(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" \) | sort)
[ ${#WALL_LIST[@]} -eq 0 ] && echo "No wallpaper found in $WALL_DIR" && exit 1

set_wall() {
    local wall="$1"
    [ ! -f "$wall" ] && echo "File not found: $wall" && exit 1
    ln -fs "$wall" "$CURRENT_WALL"
    synchronize_colors "$wall"
    swww img "$wall"
}

synchronize_colors() {
    local wall="$1"
    wal -i "$wall"
    swaync-client --reload-css
    pywalfox update
    ln -fs "$CACHE_DIR/wal/colors-kitty.conf" "$HOME/.config/kitty/colors-kitty.conf"
    fix_pywal_colors
}

fix_pywal_colors() {
    local colors=$(awk '
        /\{/ {if(count==0) start=1; count++}
        start {print}
        /\}/ {if(start){count--; if(count==0) exit}}
        ' "$CACHE_DIR/wal/colors-rofi-dark.rasi")
    echo "$colors" > "$CACHE_DIR/wal/colors-rofi-dark.rasi"
}

next_wall() {
    local cur="$(basename "$(readlink -f "$CURRENT_WALL" 2>/dev/null)")"
    local idx=0
    for i in "${!WALL_LIST[@]}"; do
        if [[ "$(basename "${WALL_LIST[$i]}")" == "$cur" ]]; then
            idx=$i
            break
        fi
    done
    local next=$(((idx + 1) % ${#WALL_LIST[@]}))
    set_wall "${WALL_LIST[$next]}"
}

prev_wall() {
    local cur="$(basename "$(readlink -f "$CURRENT_WALL" 2>/dev/null)")"
    local idx=0
    for i in "${!WALL_LIST[@]}"; do
        if [[ "$(basename "${WALL_LIST[$i]}")" == "$cur" ]]; then
            idx=$i
            break
        fi
    done
    local prev=$(((idx - 1 + ${#WALL_LIST[@]}) % ${#WALL_LIST[@]}))
    set_wall "${WALL_LIST[$prev]}"
}

random_wall() {
    local idx=$((RANDOM % ${#WALL_LIST[@]}))
    set_wall "${WALL_LIST[$idx]}"
}

select_wall() {
    local choice
    choice=$(printf '%s\n' "${WALL_LIST[@]}" | rofi -dmenu -p "Escolha o wallpaper")
    [ -n "$choice" ] && set_wall "$choice"
}

case "$1" in
--next | -n) next_wall ;;
--prev | -p) prev_wall ;;
--random | -r) random_wall ;;
--set | -s) set_wall "$2" ;;
--select | -S) select_wall ;;
--current | -c) readlink -f "$CURRENT_WALL" ;;
*) echo "Usage: $0 [ --next | --prev | --random | --set <file> | --select | --current ]" ;;
esac
