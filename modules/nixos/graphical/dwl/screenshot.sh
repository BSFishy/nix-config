#!/usr/bin/env bash
set -euo pipefail

geometry="$(@SLURP@)" || exit 0
[[ -n "$geometry" ]] || exit 0

screenshot_dir="$HOME/Pictures/Screenshots"
mkdir -p "$screenshot_dir"
filename="$screenshot_dir/$(date '+%Y-%m-%d_%H-%M-%S').png"
@GRIM@ -g "$geometry" "$filename"
@NOTIFY@ "Screenshot saved" "$filename"
