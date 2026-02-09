#!/usr/bin/env bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100)
  ICON="󰁹 " COLOR="0xff98971a"
  ;;
[6-8][0-9])
  ICON="󰂀 " COLOR="0xffffffff"
  ;;
[3-5][0-9])
  ICON="󰁼 " COLOR="0xffd79921"
  ;;
[1-2][0-9])
  ICON="󰁺 " COLOR="0xffd65d0e"
  ;;
*) ICON="󰂎 " COLOR="0xffcc241d" ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="󰂄 " COLOR="0xff98971a"
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.color="$COLOR"
