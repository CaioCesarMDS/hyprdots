#!/usr/bin/env bash

set -euo pipefail

dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/powermenu/"

if ! command -v rofi &>/dev/null; then
    echo "Error: rofi is not installed." >&2
    exit 1
fi

lastlogin="$(last -n1 "$USER" \
    | grep -E 'still logged in|logged in' \
    | head -n1 \
    | tr -s ' ' \
    | awk '{print $4" "$5" "$6}')"

uptime=$(uptime -p | awk '{$1=""; print substr($0,2)}')
host=$(hostname)

shutdown=''
reboot=''
lock='󰌾'
hibernate='󰤄'
suspend='󰏤'
logout='󰍃'
yes=''
no='󰅙'

rofi_cmd() {
    rofi -dmenu \
        -p " $USER@$host" \
        -mesg " Last Login: $lastlogin |  Uptime: $uptime" \
        -theme "${dir}/powermenu.rasi"
}

confirm_cmd() {
    rofi -dmenu \
        -p "Confirmation" \
        -mesg "Are you sure?" \
        -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -theme "${dir}/powermenu.rasi"
}

confirm_exit() {
    printf "%s\n%s\n" "$yes" "$no" | confirm_cmd
}

run_rofi() {
    printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
        "$lock" "$suspend" "$logout" "$hibernate" "$reboot" "$shutdown" | rofi_cmd
}

run_cmd() {
    selected="$(confirm_exit)"
    if [[ "${selected// /}" == "${yes// /}" ]]; then
        case "$1" in
            --shutdown) systemctl poweroff ;;
            --reboot) systemctl reboot ;;
            --logout) hyprctl dispatch exit 0 ;;
            --lock) hyprlock ;;
            --suspend) systemctl suspend ;;
            --hibernate) systemctl hibernate ;;
        esac
    fi
}

chosen="$(run_rofi)"

case "$chosen" in
    "$shutdown") run_cmd --shutdown ;;
    "$reboot") run_cmd --reboot ;;
    "$logout") run_cmd --logout ;;
    "$lock") run_cmd --lock ;;
    "$suspend") run_cmd --suspend ;;
    "$hibernate") run_cmd --hibernate ;;
esac
