set -euo pipefail

case "${1:-}" in
"")
  printf "Sleep\nLogout\nReboot\nShutdown\n"
  ;;
"Sleep")
  loginctl lock-session
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
