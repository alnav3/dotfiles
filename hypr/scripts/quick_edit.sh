#!/usr/bin/env bash

CACHE=~/.cache/quick-edit-dirs

# Create/update cache if it doesn't exist
if [ ! -f "$CACHE" ]; then
    find ~/dev -name ".git" -type d 2>/dev/null | sed "s|/.git||" | sort -r > "$CACHE"
fi

# Check if kitty with tmux develop session is running
is_develop_session_running() {
    tmux has-session -t develop 2>/dev/null
}

# Check if focused window is kitty with tmux
is_kitty_with_tmux_focused() {
    local focused_class focused_title
    focused_class=$(hyprctl -j activewindow | jq -r '.class')
    focused_title=$(hyprctl -j activewindow | jq -r '.title')

    [[ "$focused_class" == "kitty" ]] && [[ "$focused_title" == *"tmux"* || "$focused_title" == *"develop"* ]]
}

# Main logic
if is_kitty_with_tmux_focused && is_develop_session_running; then
    # Kitty is focused and develop session exists, create new tmux window with fzf
    tmux new-window -t develop "cd \$(cat $CACHE | fzf --tac) && exec nvim ."
else
    # Either not kitty focused or no develop session, open new kitty window
    exec kitty -e sh -c "cd \$(cat $CACHE | fzf --tac) && exec nvim ."
fi
