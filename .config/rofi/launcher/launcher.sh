#!/usr/bin/env bash

dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/launcher/"

if ! command -v rofi &>/dev/null; then
    echo "Error: rofi is not installed." >&2
    exit 1
fi

rofi \
    -show drun \
    -theme ${dir}/launcher.rasi
