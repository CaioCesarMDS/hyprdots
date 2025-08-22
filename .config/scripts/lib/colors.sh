#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

readonly CONFIG_DIR="$HOME/.config"
readonly CACHE_DIR="$HOME/.cache"
readonly WAL_COLORS_HYPR="$CACHE_DIR/wal/colors-hyprland.conf"
readonly HYPR_COLORS_CONF="$CONFIG_DIR/hypr/config/colors.conf"

check_command() {
  ensure_command swaync
  ensure_command pywalfox
  ensure_command wal
}

check_directories() {
  ensure_directory "$WAL_COLORS_HYPR"
  ensure_directory "$HYPR_COLORS_CONF"
  ensure_directory "$CACHE_DIR/wal"
}

hyprland_rgba_patch() {
  local TEMP="$WAL_COLORS_HYPR.tmp"
  awk -v OFS=" = " '
        /^[[:space:]]*#/ || NF==0 { print; next }
        {
            split($0, kv, "=")
            key=kv[1]; gsub(/^[ \t]+|[ \t]+$/, "", key)
            val=kv[2]; gsub(/^[ \t]+|[ \t]+$/, "", val)
            if (val ~ /^#[0-9A-Fa-f]{6}$/) {
                r=strtonum("0x" substr(val,2,2))
                g=strtonum("0x" substr(val,4,2))
                b=strtonum("0x" substr(val,6,2))
                val="rgba("r","g","b",1)"
            }
            print key, val
        }
    ' "$WAL_COLORS_HYPR" >"$TEMP" && mv "$TEMP" "$HYPR_COLORS_CONF"
}

apply_colorscheme() {
  local wall="$1"

  check_directories
  check_command

  wal -i "$wall"
  hyprland_rgba_patch

  ensure_symlink "$CACHE_DIR/wal/colors-kitty.conf" "$CONFIG_DIR/kitty/colors-kitty.conf"
  swaync-client --reload-css
  pywalfox update
}
