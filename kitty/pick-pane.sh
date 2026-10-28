#!/bin/sh

for command in kitten jq fzf; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Pane picker requires %s on PATH.\nPress Enter to close.\n' "$command" >&2
        read -r reply
        exit 1
    fi
done

# Keep IDs separate from display text, and escape control characters in titles.
windows=$(kitten @ ls) || exit 1
rows=$(printf '%s\n' "$windows" | jq -r '
    .[] | .tabs[] | . as $tab | .windows[] |
    select((.id | tostring) != env.KITTY_WINDOW_ID) |
    [.id, .title, $tab.title] | @tsv
') || exit 1

selection=$(printf '%s\n' "$rows" | fzf \
    --delimiter="$(printf '\t')" \
    --with-nth=2,3 --nth=1 \
    --prompt='Pane title> ' \
    --header='Pane title / tab — Enter: focus, Esc: cancel' \
    --layout=reverse --no-multi) || exit 0

[ -n "$selection" ] || exit 0
id=${selection%%"$(printf '\t')"*}
kitten @ focus-window --match "id:$id"
