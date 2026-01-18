#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
"")
  printf "Sleep\nLogout\nReboot\nShutdown\n"
  ;;
"Sleep")
  # TODO: add hyprlock
  hyprlock &
  sleep 0.3
  systemctl suspend
  ;;
"Logout")
  hyprctl dispatch exit
  ;;
"Reboot")
  systemctl reboot
  ;;
"Shutdown")
  systemctl poweroff
  ;;
esac
