#!/bin/bash

DIRS=(
    "$HOME/Documents"
    "$HOME/code"
    "$HOME/.config"
    "$HOME/Downloads"
    "$HOME"
)

if [[ $# -eq 1 ]]; then 
    selected=$1
else
    selected=$(find -L "${DIRS[@]}" -maxdepth 1 -type d \
        | sed "s|^$HOME/||" \
        | fzf --margin="10%" --color="bw" --layout=reverse --no-scrollbar --no-info --select-1)
    [[ $selected ]] && selected="$HOME/$selected"
fi

[[ ! $selected ]] && exit 0

selected_name=$(basename "$selected" | tr . _)
if ! tmux has-session -t "$selected_name"; then
    tmux new-session -ds "$selected_name" -c "$selected"
    tmux select-window -t "$selected_name:1"
fi

tmux switch-client -t "$selected_name"
