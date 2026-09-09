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

case "$action" in
  new)
    exec treehouse get
    ;;
  existing:*)
    exec treehouse enter "${action#existing:}"
    ;;
esac
