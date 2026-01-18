#!/usr/bin/env

set -euo pipefail

exec rofi -modes combi -show combi -combi-modes "drun,window,Power:rofi-power"
