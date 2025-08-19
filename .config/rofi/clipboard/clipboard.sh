#!/usr/bin/env bash

pkill -u "$USER" rofi 2>/dev/null && exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
FAVORITES_FILE="$CACHE_DIR/clipboard/clipboard_favorites"
ROFI_STYLE="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/clipboard/clipboard.rasi"

DEL_MODE=false

run_rofi() {
    local placeholder="$1"; shift
    rofi -dmenu \
        -theme-str "entry { font: 'JetBrainsMono Nerd Font 24'; placeholder: '$placeholder'; }" \
        -theme "$ROFI_STYLE" "$@"
}

ensure_favorites_dir() {
    mkdir -p "$(dirname "$FAVORITES_FILE")"
}

process_selections() {
    if [ "$DEL_MODE" != true ]; then
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            decoded=$(echo -e "$line\t" | cliphist decode)
            echo "$decoded"
        done
    else
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            cliphist delete <<<"$line"
            notify-send "Deleted" "$line"
        done
        exit 0
    fi
}

# -------------------
# Histórico
# -------------------

show_history() {
    mapfile -t items < <(cliphist list | sed '/^\s*$/d')
    [ ${#items[@]} -eq 0 ] && return
    selection=$(printf '%s\n' "${items[@]}" | run_rofi " History" -multi-select -i -display-columns 2 -selected-row 1)
    [ -z "$selection" ] && exit 0
    process_selections <<<"$selection" | wl-copy
}

delete_items() {
    DEL_MODE=true
    mapfile -t items < <(cliphist list | sed '/^\s*$/d')
    [ ${#items[@]} -eq 0 ] && return
    printf '%s\n' "${items[@]}" | run_rofi " Delete" -multi-select -i -display-columns 2 | process_selections
}

clear_history() {
    cliphist wipe && notify-send "Clipboard history cleared."
}

# -------------------
# Favoritos
# -------------------

add_to_favorites() {
    ensure_favorites_dir
    mapfile -t items < <(cliphist list | sed '/^\s*$/d')
    [ ${#items[@]} -eq 0 ] && return
    selection=$(printf '%s\n' "${items[@]}" | run_rofi " Add to Favorites")
    [ -z "$selection" ] && return
    encoded=$(echo "$selection" | cliphist decode | base64 -w0)
    grep -Fxq "$encoded" "$FAVORITES_FILE" 2>/dev/null || echo "$encoded" >>"$FAVORITES_FILE"
    notify-send "Added to favorites."
}

view_favorites() {
    [ -f "$FAVORITES_FILE" ] && [ -s "$FAVORITES_FILE" ] || { notify-send "No favorites."; return; }
    mapfile -t favs < "$FAVORITES_FILE"
    decoded=()
    for f in "${favs[@]}"; do
        decoded+=("$(echo "$f" | base64 --decode | tr '\n' ' ')")
    done
    selection=$(printf '%s\n' "${decoded[@]}" | run_rofi "󰓎 View Favorites")
    [ -z "$selection" ] && return
    idx=$(printf '%s\n' "${decoded[@]}" | grep -nxF "$selection" | cut -d: -f1)
    [ -z "$idx" ] && { notify-send "Error"; return; }
    echo "${favs[$((idx-1))]}" | base64 --decode | wl-copy
    notify-send "Copied to clipboard."
}

delete_from_favorites() {
    [ -f "$FAVORITES_FILE" ] && [ -s "$FAVORITES_FILE" ] || { notify-send "No favorites."; return; }
    mapfile -t favs < "$FAVORITES_FILE"
    decoded=()
    for f in "${favs[@]}"; do
        decoded+=("$(echo "$f" | base64 --decode | tr '\n' ' ')")
    done
    selection=$(printf '%s\n' "${decoded[@]}" | run_rofi " Remove Favorites")
    [ -z "$selection" ] && return
    idx=$(printf '%s\n' "${decoded[@]}" | grep -nxF "$selection" | cut -d: -f1)
    [ -z "$idx" ] && { notify-send "Error"; return; }
    sed "${idx}d" "$FAVORITES_FILE" >"$FAVORITES_FILE.tmp" && mv "$FAVORITES_FILE.tmp" "$FAVORITES_FILE"
    notify-send "Item removed from favorites."
}

clear_favorites() {
    [ -f "$FAVORITES_FILE" ] && : >"$FAVORITES_FILE" && notify-send "All favorites cleared."
}

# -------------------
# Menu principal
# -------------------

main_menu() {
    menu_items=(" History" " Delete" "󰓎 View Favorites" "󱙩 Manage Favorites" "󰆴 Clear History")
    selection=$(printf '%s\n' "${menu_items[@]}" | run_rofi "Clipboard Manager")
    echo "$selection"
}

main() {
    action="$1"; shift
    [ -z "$action" ] && action=$(main_menu)
    case "$action" in
        " History") show_history ;;
        " Delete") delete_items ;;
        "󰓎 View Favorites") view_favorites ;;
        "󱙩 Manage Favorites")
            manage_menu=(" Add" " Delete" "󰆴 Clear")
            manage=$(printf '%s\n' "${manage_menu[@]}" | run_rofi "Manage Favorites")
            case "$manage" in
                " Add") add_to_favorites ;;
                " Delete") delete_from_favorites ;;
                "󰆴 Clear") clear_favorites ;;
            esac
            ;;
        "󰆴 Clear History") clear_history ;;
    esac
}

main "$@"
