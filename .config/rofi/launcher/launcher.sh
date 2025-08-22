#!/usr/bin/env bash
set -euo pipefail

pkill -u "$USER" rofi 2>/dev/null && exit 0

readonly LAUNCHER_THEME_FILE="$HOME/.config/rofi/launcher/launcher.rasi"

[ -f "$LAUNCHER_THEME_FILE" ] || { echo "File not found: $LAUNCHER_THEME_FILE" >&2; exit 1; }

rofi -show drun -theme "$LAUNCHER_THEME_FILE"
