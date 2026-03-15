#!/usr/bin/env bash

# Requires 'jq' and 'hyprctl' available in PATH

# Check if focused window is kitty with tmux
is_kitty_with_tmux_focused() {
    local focused_class focused_title
    focused_class=$(hyprctl -j activewindow | jq -r '.class')
    focused_title=$(hyprctl -j activewindow | jq -r '.title')
    
    [[ "$focused_class" == "kitty" ]] && [[ "$focused_title" == *"tmux"* ]]
}

# Check if any tmux session is running
has_tmux_sessions() {
    tmux list-sessions >/dev/null 2>&1
}

# Check for special case: kitty with tmux focused and any tmux session exists
if is_kitty_with_tmux_focused && has_tmux_sessions; then
    # Get number of tmux windows in current session
    TMUX_WINDOW_COUNT=$(tmux list-windows | wc -l)
    
    if [ "$TMUX_WINDOW_COUNT" -gt 1 ]; then
        # More than one tmux window, close the current one
        tmux kill-window
        exit 0
    else
        # Only one tmux window left, proceed with normal window closing behavior
        # (this will close the entire kitty window)
        :  # continue to normal logic below
    fi
fi

# Get active workspace ID
ACTIVE_WS=$(hyprctl -j activewindow | jq -r '.workspace.id')
if [ -z "$ACTIVE_WS" ] || [ "$ACTIVE_WS" = "null" ]; then
    exit 0
fi

# Get all windows on active workspace
WINDOWS=$(hyprctl -j clients | jq --argjson ws "$ACTIVE_WS" -r '.[] | select(.workspace.id == $ws) | .address')

# Count windows
WINDOW_COUNT=$(echo "$WINDOWS" | wc -l)

# Get focused window address
FOCUSED_WIN=$(hyprctl -j activewindow | jq -r '.address')

if [ "$WINDOW_COUNT" -gt 2 ]; then
    # More than 2 windows: just close the focused window
    hyprctl dispatch closewindow address:"$FOCUSED_WIN"
else
    # 2 or fewer windows: close focused window, then dissolve group if any remain

    # Close focused window
    hyprctl dispatch closewindow address:"$FOCUSED_WIN"

    # Wait a short moment to allow Hyprland to update window list
    sleep 0.1

    # Get remaining windows on workspace
    REMAINING_WINDOWS=$(hyprctl -j clients | jq --argjson ws "$ACTIVE_WS" -r '.[] | select(.workspace.id == $ws) | .address')

    # Ungroup any remaining windows (if grouped)
    for win in $REMAINING_WINDOWS; do
        # Check if window is grouped
        IS_GROUPED=$(hyprctl -j clients | jq --arg addr "$win" '.[] | select(.address == $addr) | .grouped | length')
        if [ "$IS_GROUPED" -gt 0 ]; then
            hyprctl dispatch moveoutofgroup address:"$win"
        fi
    done
fi

