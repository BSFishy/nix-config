#!/usr/bin/env bash
MAX_KEEP=10

mapfile -t sessions < <(tmux list-sessions -F "#{session_activity} #{session_name}" | sort -r | awk '{print $2}')
count=${#sessions[@]}

for ((i = MAX_KEEP; i < count; i++)); do
  tmux kill-session -t "${sessions[i]}"
done
