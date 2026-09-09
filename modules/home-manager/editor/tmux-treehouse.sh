status_json=$(treehouse status --json)

selection=$(
  jq -r '
    (["new", "＋ Start a new Treehouse shell"] | @tsv),
    (.[] | ["existing:\(.name)", "  \(.name)  [\(.status)]  \(.path)"] | @tsv)
  ' <<<"$status_json" \
    | fzf \
      --delimiter=$'\t' \
      --with-nth=2 \
      --layout=reverse \
      --border \
      --prompt='Treehouse › ' \
      --header='Start a new shell or open an existing worktree'
) || exit 0

action=${selection%%$'\t'*}
treehouse_bin=$(command -v treehouse)

case "$action" in
  new)
    printf -v command '%q ' "$treehouse_bin" get
    ;;
  existing:*)
    printf -v command '%q ' "$treehouse_bin" enter "${action#existing:}"
    ;;
esac

tmux new-window -c "$PWD" "$command"
