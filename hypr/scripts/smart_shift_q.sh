#!/usr/bin/env bash

CACHE=~/.cache/quick-edit-dirs

# Create/update cache if it doesn't exist
if [ ! -f "$CACHE" ]; then
    find ~/dev -name ".git" -type d 2>/dev/null | sed "s|/.git||" | sort -r > "$CACHE"
fi

# Check if kitty with tmux is focused
is_kitty_with_tmux_focused() {
    local focused_class focused_title
    focused_class=$(hyprctl -j activewindow | jq -r '.class' 2>/dev/null)
    focused_title=$(hyprctl -j activewindow | jq -r '.title' 2>/dev/null)
    
    [[ "$focused_class" == "kitty" ]] && [[ "$focused_title" == *"tmux"* ]]
}

# Check if app is already running and return workspace ID if found
find_running_app() {
    local app_name="$1"
    if command -v jq >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
        hyprctl -j clients | jq -r --arg app "$app_name" '.[] | select(.class // .initialClass | test($app; "i")) | .workspace.id' 2>/dev/null | head -1
    fi
}

# Check if any tmux session is running
has_tmux_sessions() {
    tmux list-sessions >/dev/null 2>&1
}

# Main logic
if has_tmux_sessions; then
    local kitty_workspace
    kitty_workspace=$(find_running_app "kitty")
    
    if [ -n "$kitty_workspace" ]; then
        # Kitty is running somewhere
        if [ "$kitty_workspace" = "1" ]; then
            # Kitty is in workspace 1, go there and send command to current tmux session
            hyprctl dispatch workspace 1
            sleep 0.2
            hyprctl dispatch focuswindow "class:kitty"
            
            # Use tmux without specifying session - this will use the current session
            if is_kitty_with_tmux_focused; then
                tmux new-window "cd \$(cat $CACHE | fzf --tac) && exec nvim ."
            else
                # Fallback to develop if not in tmux context
                tmux new-window -t develop "cd \$(cat $CACHE | fzf --tac) && exec nvim ."
            fi
            # Ensure focus stays on kitty after tmux window creation
            sleep 0.2
            hyprctl dispatch focuswindow "class:kitty"
        else
            # Kitty is not in workspace 1, open new kitty in workspace 1
            hyprctl dispatch exec "[workspace 1 silent] kitty -e sh -c 'cd \$(cat $CACHE | fzf --tac) && exec nvim .'"
            hyprctl dispatch workspace 1
            # Focus the newly opened kitty window
            sleep 0.3
            hyprctl dispatch focuswindow "class:kitty"
        fi
        exit 0
    fi
fi

# Either no tmux session or no kitty running, open new kitty in workspace 1
hyprctl dispatch exec "[workspace 1 silent] kitty -e sh -c 'cd \$(cat $CACHE | fzf --tac) && exec nvim .'"
hyprctl dispatch workspace 1
# Focus the newly opened kitty window
sleep 0.3
hyprctl dispatch focuswindow "class:kitty"