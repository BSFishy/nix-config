# shellcheck shell=bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PI_BIN=${PI_BIN:-pi}
PI_EXTENSION=${PI_EXTENSION:-"$SCRIPT_DIR/pi-attention.ts"}
TMUX_BIN=${TMUX_BIN:-tmux}
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pi-attention-extension-test.XXXXXX")
SOCKET="$TEST_DIR/tmux.sock"
HOME_DIR="$TEST_DIR/home"
LAUNCHER="$TEST_DIR/launch-pi"

cleanup() {
  "$TMUX_BIN" -S "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$HOME_DIR"
printf '#!%s\ncd %q\nexec env HOME=%q %q --extension %q\n' \
  "${BASH:-/bin/bash}" \
  "$HOME_DIR" \
  "$HOME_DIR" \
  "$PI_BIN" \
  "$PI_EXTENSION" > "$LAUNCHER"
chmod +x "$LAUNCHER"

"$TMUX_BIN" -S "$SOCKET" -f /dev/null new-session -d -s pi-attention-extension
"$TMUX_BIN" -S "$SOCKET" set-option -g remain-on-exit on
"$TMUX_BIN" -S "$SOCKET" respawn-pane -k -t pi-attention-extension:0.0 "$LAUNCHER"
pane=$("$TMUX_BIN" -S "$SOCKET" display-message -p -t pi-attention-extension:0.0 '#{pane_id}')

session_id=''
for ((attempt = 0; attempt < 100; attempt++)); do
  session_id=$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane" @pi_session_id 2>/dev/null || true)
  [[ -n "$session_id" ]] && break
  sleep 0.1
done
if [[ -z "$session_id" ]]; then
  "$TMUX_BIN" -S "$SOCKET" capture-pane -p -t "$pane" >&2
  printf 'not ok - Pi startup did not register its pane\n' >&2
  exit 1
fi

attention=$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane" @pi_attention 2>/dev/null || true)
[[ -z "$attention" ]] || {
  printf 'not ok - Pi startup retained stale attention state\n' >&2
  exit 1
}
printf 'ok - Pi startup registered pane %s\n' "$pane"

"$TMUX_BIN" -S "$SOCKET" send-keys -t "$pane" C-d
pane_dead=0
for ((attempt = 0; attempt < 100; attempt++)); do
  pane_dead=$("$TMUX_BIN" -S "$SOCKET" display-message -p -t "$pane" '#{pane_dead}')
  [[ "$pane_dead" == 1 ]] && break
  sleep 0.1
done
if [[ "$pane_dead" != 1 ]]; then
  "$TMUX_BIN" -S "$SOCKET" capture-pane -p -t "$pane" >&2
  printf 'not ok - Pi did not exit after Ctrl-D\n' >&2
  exit 1
fi

session_id=$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane" @pi_session_id 2>/dev/null || true)
[[ -z "$session_id" ]] || {
  printf 'not ok - Pi shutdown retained pane metadata\n' >&2
  exit 1
}
printf 'ok - Pi shutdown unregistered pane %s\n' "$pane"
