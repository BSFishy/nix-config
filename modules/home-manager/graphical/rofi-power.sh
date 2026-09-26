set -euo pipefail

case "${1:-}" in
"")
  printf "Sleep\nLogout\nReboot\nShutdown\n"
  ;;
"Sleep")
  gtklock &
  sleep 0.5
  systemctl suspend
  ;;
"Logout")
  loginctl terminate-session "$XDG_SESSION_ID"
  ;;
"Reboot")
  systemctl reboot
  ;;
"Shutdown")
  systemctl poweroff
  ;;
esac
