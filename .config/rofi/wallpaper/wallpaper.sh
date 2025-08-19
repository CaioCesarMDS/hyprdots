#!/usr/bin/env bash

WALL_CHANGE_SCRIPT="$HOME/.config/scripts/wallpaper.sh"

if [[ ! -f "$WALL_CHANGE_SCRIPT" ]]; then
    exit 1
fi

"$WALL_CHANGE_SCRIPT" --select

