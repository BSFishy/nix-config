# shellcheck shell=bash
set -euo pipefail

TMUX_BIN=${TMUX_BIN:-tmux}
TMUX_SOCKET=${PI_ATTENTION_TMUX_SOCKET:-}

usage() {
  cat <<'EOF'
Usage:
  pi-attention register [--pane PANE] [--session-id ID] [--session-file PATH]
                        [--project NAME] [--label LABEL] [--owner-pid PID]
  pi-attention set waiting|unread [PANE]
  pi-attention transition waiting|unread waiting|unread [PANE]
  pi-attention read [PANE]
  pi-attention unregister [PANE]
  pi-attention count
  pi-attention status
  pi-attention list
EOF
}

fail() {
  printf 'pi-attention: %s\n' "$*" >&2
  exit 1
}

tmux_cmd() {
  if [[ -n "$TMUX_SOCKET" ]]; then
    "$TMUX_BIN" -S "$TMUX_SOCKET" "$@"
  else
    "$TMUX_BIN" "$@"
  fi
}

require_pane() {
  local pane=${1:-${TMUX_PANE:-}}
  [[ -n "$pane" ]] || fail 'no pane specified and TMUX_PANE is unset'
  printf '%s\n' "$pane"
}

set_pane_option() {
  local pane=$1
  local option=$2
  local value=$3
  value=$(printf '%s' "$value" | tr '\t\r\n' '   ')
  value=${value//__PI_ATTENTION__/ }
  tmux_cmd set-option -pq -t "$pane" "$option" "$value"
}

unset_pane_option() {
  local pane=$1
  local option=$2
  tmux_cmd set-option -pqu -t "$pane" "$option"
}

set_optional_pane_option() {
  local pane=$1
  local option=$2
  local value=$3

  if [[ -n "$value" ]]; then
    set_pane_option "$pane" "$option" "$value"
  else
    unset_pane_option "$pane" "$option"
  fi
}

register_pane() {
  local pane=${TMUX_PANE:-}
  local session_id=${PI_ATTENTION_SESSION_ID:-${PI_SESSION_ID:-}}
  local session_file=${PI_ATTENTION_SESSION_FILE:-${PI_SESSION_FILE:-}}
  local project=${PI_ATTENTION_PROJECT:-${PWD##*/}}
  local label=${PI_ATTENTION_LABEL:-}
  local owner_pid=${PI_ATTENTION_OWNER_PID:-$PPID}

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pane)
        [[ $# -ge 2 ]] || fail '--pane requires a value'
        pane=$2
        shift 2
        ;;
      --session-id)
        [[ $# -ge 2 ]] || fail '--session-id requires a value'
        session_id=$2
        shift 2
        ;;
      --session-file)
        [[ $# -ge 2 ]] || fail '--session-file requires a value'
        session_file=$2
        shift 2
        ;;
      --project)
        [[ $# -ge 2 ]] || fail '--project requires a value'
        project=$2
        shift 2
        ;;
      --label)
        [[ $# -ge 2 ]] || fail '--label requires a value'
        label=$2
        shift 2
        ;;
      --owner-pid)
        [[ $# -ge 2 ]] || fail '--owner-pid requires a value'
        owner_pid=$2
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "unknown register option: $1"
        ;;
    esac
  done

  pane=$(require_pane "$pane")
  [[ -n "$session_id" ]] || session_id="pane-${pane#%}"
  [[ -n "$project" ]] || project='unknown'
  [[ "$owner_pid" =~ ^[0-9]+$ ]] || fail 'owner PID must be numeric'

  set_pane_option "$pane" @pi_session_id "$session_id"
  set_optional_pane_option "$pane" @pi_session_file "$session_file"
  set_pane_option "$pane" @pi_project "$project"
  set_optional_pane_option "$pane" @pi_label "$label"
  set_pane_option "$pane" @pi_owner_pid "$owner_pid"
  set_pane_option "$pane" @pi_updated_at "$(date +%s)"
}

validate_attention_state() {
  case "$1" in
    waiting|unread) ;;
    *) fail 'attention state must be waiting or unread' ;;
  esac
}

set_attention() {
  local state=${1:-}
  local pane

  validate_attention_state "$state"
  pane=$(require_pane "${2:-}")
  set_pane_option "$pane" @pi_attention "$state"
  set_pane_option "$pane" @pi_updated_at "$(date +%s)"
}

transition_attention() {
  local previous=${1:-}
  local next=${2:-}
  local pane
  local current

  validate_attention_state "$previous"
  validate_attention_state "$next"
  pane=$(require_pane "${3:-}")
  current=$(tmux_cmd show-options -pqv -t "$pane" @pi_attention)

  if [[ "$current" == "$previous" ]]; then
    set_attention "$next" "$pane"
  fi
}

read_attention() {
  local pane
  pane=$(require_pane "${1:-}")
  unset_pane_option "$pane" @pi_attention
  set_pane_option "$pane" @pi_updated_at "$(date +%s)"
}

unregister_pane() {
  local pane
  local option
  pane=$(require_pane "${1:-}")

  for option in \
    @pi_attention \
    @pi_session_id \
    @pi_session_file \
    @pi_project \
    @pi_label \
    @pi_updated_at \
    @pi_owner_pid
  do
    unset_pane_option "$pane" "$option"
  done
}

count_attention() {
  tmux_cmd list-panes -a -F '#{@pi_attention}' 2>/dev/null \
    | awk '$0 == "waiting" || $0 == "unread" { count++ } END { print count + 0 }'
}

status_attention() {
  local count
  count=$(count_attention 2>/dev/null) || return 0
  if ((count > 0)); then
    printf '󰚩 %s ' "$count"
  fi
}

list_attention() {
  local separator='__PI_ATTENTION__'
  local filter
  local format

  filter='#{||:#{==:#{@pi_attention},waiting},#{==:#{@pi_attention},unread}}'
  format="#{@pi_attention}${separator}#{session_name}:#{window_index}.#{pane_index}${separator}#{@pi_project}${separator}#{@pi_label}${separator}#{pane_id}${separator}#{window_id}${separator}#{window_name}"

  tmux_cmd list-panes -a -f "$filter" -F "$format" 2>/dev/null \
    | awk -F "$separator" 'BEGIN { OFS="\t" } NF == 7 { print $1, $2, $3, $4, $5, $6, $7 }' \
    | LC_ALL=C sort -t "$(printf '\t')" -k1,1r -k2,2
}

command=${1:-}
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command" in
  register) register_pane "$@" ;;
  set) set_attention "$@" ;;
  transition) transition_attention "$@" ;;
  read) read_attention "$@" ;;
  unregister) unregister_pane "$@" ;;
  count) count_attention "$@" ;;
  status) status_attention "$@" ;;
  list) list_attention "$@" ;;
  -h|--help|help) usage ;;
  '') usage; exit 1 ;;
  *) fail "unknown command: $command" ;;
esac
