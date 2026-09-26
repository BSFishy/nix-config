#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

somebar_bin=@SOMEBAR@
attention_bin=@ATTENTION@

export TMUX_TMPDIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

declare -A workspace_masks
declare -A fullscreen_states
declare -A last_visibility
last_agent_count=""

publish_status() {
  local battery="unknown"
  local battery_icon="󰂎"
  local capacity
  local battery_status=""
  local agents=0
  local agent_status=""

  for capacity in /sys/class/power_supply/BAT*/capacity; do
    if [[ -r "$capacity" ]]; then
      battery="$(<"$capacity")"
      battery_status="$(<"${capacity%capacity}status" 2>/dev/null || true)"
      break
    fi
  done

  case "$battery" in
    9[0-9]|100) battery_icon="󰁹" ;;
    [6-8][0-9]) battery_icon="󰂀" ;;
    [3-5][0-9]) battery_icon="󰁼" ;;
    [1-2][0-9]) battery_icon="󰁺" ;;
  esac
  if [[ "$battery_status" == Charging || "$battery_status" == Full ]]; then
    battery_icon="󰂄"
  fi
  [[ "$battery" == unknown ]] || battery+="%"

  if [[ -x "$attention_bin" ]]; then
    agents="$($attention_bin count 2>/dev/null || printf 0)"
  fi
  if [[ "$agents" =~ ^[0-9]+$ ]] && ((agents > 0)); then
    agent_status="󰚩 $agents   "
  fi

  if [[ "$agents" != "$last_agent_count" ]]; then
    printf 'dwl-status: attention count=%s display=%q\n' "$agents" "$agent_status" >&2
    last_agent_count="$agents"
  fi

  local status="${agent_status}󰃭 $(date '+%Y-%m-%d')    $(date '+%H:%M:%S')   ${battery_icon} ${battery}"
  if ! "$somebar_bin" -c status "$status"; then
    printf 'dwl-status: failed to publish status to somebar\n' >&2
  fi
}

status_loop() {
  while sleep 1; do
    publish_status
  done
}

status_loop >/dev/null </dev/null &
status_pid=$!
trap 'kill "$status_pid" 2>/dev/null || true' EXIT

while IFS= read -r line; do
  read -r monitor command rest <<<"$line"
  [[ -n "${monitor:-}" && -n "${command:-}" ]] || continue

  case "$command" in
    tags)
      read -r _occupied current_mask _client_tags _urgent <<<"$rest"
      workspace_masks["$monitor"]="${current_mask:-0}"
      ;;
    fullscreen)
      fullscreen_states["$monitor"]="${rest:-0}"
      ;;
    *)
      continue
      ;;
  esac

  mask="${workspace_masks[$monitor]:-0}"
  fullscreen="${fullscreen_states[$monitor]:-0}"
  visibility=shown
  if [[ "${last_visibility[$monitor]:-}" != "$visibility" ]]; then
    printf 'dwl-status: monitor=%s mask=%s fullscreen=%s visibility=%s\n' "$monitor" "$mask" "$fullscreen" "$visibility" >&2
    last_visibility["$monitor"]="$visibility"
    "$somebar_bin" -c show "$monitor" || printf 'dwl-status: somebar show failed for %s\n' "$monitor" >&2
  fi
done < <(tee >("$somebar_bin"))
