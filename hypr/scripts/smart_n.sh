#!/usr/bin/env bash

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
    # Kitty is focused and develop session exists, go to next tmux window
    tmux next-window
else
    # Either not kitty focused or no develop session, open notes in workspace 1
    hyprctl dispatch exec "[workspace 1 silent] kitty -e nvim ~/notes.md"
    hyprctl dispatch workspace 1
    # Give a moment for the app to launch then focus it
    sleep 0.2
    hyprctl dispatch focuswindow "class:kitty"
fi
