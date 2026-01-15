#!/bin/bash

visible_workspaces=$(aerospace list-workspaces --monitor all --visible)
selected_workspace=$(aerospace list-workspaces --focused)

workspace=""
for sid in $visible_workspaces; do
  [[ "$sid" == "$selected_workspace" ]] && sid="*$sid"
  workspace+="${workspace:+ | }$sid"
done

sketchybar --set workspace label="$workspace"
