#!/usr/bin/env bash

# Check if focused window is kitty with tmux
is_kitty_with_tmux_focused() {
    local focused_class focused_title
    focused_class=$(hyprctl -j activewindow | jq -r '.class' 2>/dev/null)
    focused_title=$(hyprctl -j activewindow | jq -r '.title' 2>/dev/null)
    
    [[ "$focused_class" == "kitty" ]] && [[ "$focused_title" == *"tmux"* ]]
}

# Check if any tmux session is running
has_tmux_sessions() {
    tmux list-sessions >/dev/null 2>&1
}

# Main logic
if is_kitty_with_tmux_focused && has_tmux_sessions; then
    # Kitty is focused and tmux session exists, create new tmux window in current session
    tmux new-window
else
    # Either not kitty focused or no tmux session, use original terminal behavior
    exec ~/.config/hypr/scripts/open_app.sh "kitty -e tmux new-session -A -s develop"
fi