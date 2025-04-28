# based on https://github.com/ThePrimeagen/.dotfiles/blob/602019e902634188ab06ea31251c01c1a43d1621/bin/.local/scripts/tmux-sessionizer

if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(find ~/projects ~/ ~/.config -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# i think this is unnecessary and that it was initially not working because i
# had a tmux session already started without this, which was causing the
# integration to not work. i still need to actually test that hypothesis, but i
# would imagine that this does absolutely nothing
if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
  export GHOSTTY_RESOURCES_DIR="$GHOSTTY_RESOURCES_DIR"
fi

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux -u new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z $TMUX ]]; then
  tmux attach-session -t "$selected_name"
else
  tmux switch-client -t "$selected_name"
fi
