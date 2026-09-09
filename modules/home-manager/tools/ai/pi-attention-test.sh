# shellcheck shell=bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PI_ATTENTION=${PI_ATTENTION:-"$SCRIPT_DIR/pi-attention.sh"}
TMUX_BIN=${TMUX_BIN:-tmux}
SOCKET_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pi-attention-test.XXXXXX")
SOCKET="$SOCKET_DIR/tmux.sock"

cleanup() {
  "$TMUX_BIN" -S "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$SOCKET_DIR"
}
trap cleanup EXIT

run_attention() {
  PI_ATTENTION_TMUX_SOCKET="$SOCKET" TMUX_BIN="$TMUX_BIN" bash "$PI_ATTENTION" "$@"
}

assert_equal() {
  local expected=$1
  local actual=$2
  local description=$3

  if [[ "$expected" != "$actual" ]]; then
    printf 'not ok - %s\nexpected: %q\nactual:   %q\n' "$description" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'ok - %s\n' "$description"
}

"$TMUX_BIN" -S "$SOCKET" -f /dev/null new-session -d -s alpha -n editor
"$TMUX_BIN" -S "$SOCKET" new-window -d -t alpha -n agent
"$TMUX_BIN" -S "$SOCKET" new-session -d -s beta -n agent

panes=()
while IFS= read -r pane; do
  panes+=("$pane")
done < <("$TMUX_BIN" -S "$SOCKET" list-panes -a -F '#{pane_id}' | sort)
[[ ${#panes[@]} -eq 3 ]] || {
  printf 'not ok - expected three test panes\n' >&2
  exit 1
}

pane_one=${panes[0]}
pane_two=${panes[1]}
pane_three=${panes[2]}

run_attention register --pane "$pane_one" --session-id session-one --project 'project one' --label 'first agent' --owner-pid "$$"
run_attention register --pane "$pane_two" --session-id session-two --project 'project two' --label 'second agent' --owner-pid "$$"
run_attention register --pane "$pane_three" --session-id session-three --project 'project three' --owner-pid "$$"

assert_equal '0' "$(run_attention count)" 'registered panes start without attention'
assert_equal '' "$(run_attention status)" 'empty inbox has no status text'

run_attention set unread "$pane_one"
assert_equal '1' "$(run_attention count)" 'unread pane increments count'
assert_equal '󰚩 1 ' "$(run_attention status)" 'status displays one attention pane'
run_attention set unread "$pane_one"
assert_equal '1' "$(run_attention count)" 'repeated events in one pane retain one count'

run_attention set waiting "$pane_two"
assert_equal '2' "$(run_attention count)" 'waiting pane increments count'
assert_equal '󰚩 2 ' "$(run_attention status)" 'status aggregates waiting and unread panes'
run_attention transition waiting unread "$pane_two"
assert_equal 'unread' "$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane_two" @pi_attention)" 'matching transition updates state'
run_attention set waiting "$pane_two"

list_output=$(run_attention list)
list_count=$(printf '%s\n' "$list_output" | wc -l | tr -d ' ')
if [[ "$list_count" != '2' ]]; then
  printf 'diagnostic list output: %q\n' "$list_output" >&2
  "$TMUX_BIN" -S "$SOCKET" list-panes -a -F '#{pane_id} attention=#{@pi_attention} project=#{@pi_project} label=#{@pi_label}' >&2
fi
assert_equal '2' "$list_count" 'list contains only attention panes'
assert_equal 'waiting' "$(printf '%s\n' "$list_output" | awk -F '\t' 'NR == 1 { print $1 }')" 'waiting panes sort before unread panes'
assert_equal '1' "$(printf '%s\n' "$list_output" | awk -F '\t' '$1 == "unread" { count++ } END { print count + 0 }')" 'list includes unread state'
assert_equal '1' "$(printf '%s\n' "$list_output" | awk -F '\t' '$1 == "waiting" { count++ } END { print count + 0 }')" 'list includes waiting state'

fake_fzf="$SOCKET_DIR/fzf"
{
  printf '#!%s\n' "${BASH:-/bin/bash}"
  cat <<'EOF'
IFS= read -r selection
printf '%s\n' "$selection"
EOF
} > "$fake_fzf"
chmod +x "$fake_fzf"
control_input="$SOCKET_DIR/control-input"
mkfifo "$control_input"
exec 9<> "$control_input"
"$TMUX_BIN" -S "$SOCKET" -C attach-session -t beta <&9 > "$SOCKET_DIR/control-output" 2>&1 &
control_pid=$!
client=''
for ((attempt = 0; attempt < 100; attempt++)); do
  client=$("$TMUX_BIN" -S "$SOCKET" list-clients -F '#{client_name}' | head -n 1)
  [[ -n "$client" ]] && break
  sleep 0.1
done
[[ -n "$client" ]] || {
  printf 'not ok - control client did not attach\n' >&2
  exit 1
}
FZF_BIN="$fake_fzf" PI_ATTENTION_TMUX_CLIENT="$client" run_attention pick
expected_target=$("$TMUX_BIN" -S "$SOCKET" display-message -p -t "$pane_two" '#{session_id} #{window_id} #{pane_id}')
actual_target=$("$TMUX_BIN" -S "$SOCKET" display-message -p -c "$client" '#{session_id} #{window_id} #{pane_id}')
assert_equal "$expected_target" "$actual_target" 'picker focuses the selected session, window, and pane'
assert_equal 'waiting' "$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane_two" @pi_attention)" 'picker preserves attention state'
kill "$control_pid" 2>/dev/null || true
exec 9>&-

run_attention read "$pane_one"
assert_equal '1' "$(run_attention count)" 'read clears only the target pane'
run_attention transition waiting unread "$pane_one"
assert_equal '' "$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane_one" @pi_attention)" 'transition preserves a nonmatching state'

run_attention unregister "$pane_two"
assert_equal '0' "$(run_attention count)" 'unregister removes attention state'
assert_equal '' "$("$TMUX_BIN" -S "$SOCKET" show-options -pqv -t "$pane_two" @pi_session_id)" 'unregister removes metadata'

unsafe_label=$'line\tbreak\n__PI_ATTENTION__tail'
run_attention register --pane "$pane_three" --session-id session-three --project 'project three' --label "$unsafe_label" --owner-pid "$$"
run_attention set unread "$pane_three"
assert_equal 'line break  tail' "$(run_attention list | awk -F '\t' '{ print $4 }')" 'list metadata is sanitized'
run_attention read "$pane_three"

"$TMUX_BIN" -S "$SOCKET" set-option -pq -t "$pane_three" @pi_attention invalid
assert_equal '0' "$(run_attention count)" 'unknown state is ignored'
assert_equal '' "$(run_attention list)" 'unknown state is omitted from list'

printf 'all pi-attention tests passed\n'
