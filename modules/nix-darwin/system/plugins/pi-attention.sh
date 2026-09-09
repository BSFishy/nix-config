#!/usr/bin/env bash

PI_ATTENTION="/etc/profiles/per-user/$(id -un)/bin/pi-attention"
count=0

if [[ -x "$PI_ATTENTION" ]]; then
  count=$($PI_ATTENTION count 2>/dev/null || printf '0')
fi

if [[ "$count" =~ ^[0-9]+$ ]] && ((count > 0)); then
  sketchybar --set "$NAME" drawing=on label="$count"
else
  sketchybar --set "$NAME" drawing=off
fi
