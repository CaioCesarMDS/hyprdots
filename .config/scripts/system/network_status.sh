#!/usr/bin/env bash

output=""

check_network() {
  local status strength level icon
  status="$(nmcli general status | grep -oh '\w*connect\w*')"

  case "$status" in
    disconnected) output+="󰤮 " ;;
    connecting)   output+="󱍸 " ;;
    connected)
      strength="$(nmcli -t -f ACTIVE,SIGNAL dev wifi | awk -F: '/^yes/{print $2}')"
      if [[ -n "$strength" ]]; then
        level=$(( strength / 25 ))
        case $level in
          0) icon="󰤯" ;;
          1) icon="󰤟" ;;
          2) icon="󰤢" ;;
          3) icon="󰤥" ;;
          4) icon="󰤨" ;;
        esac
        output+="$icon $strength%"
      else
        output+="󰈀 "
      fi
    ;;
  esac
}

check_network
echo "$output"
