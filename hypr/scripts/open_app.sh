#!/usr/bin/env bash
# open_app.sh
# Smart Hypr/Rofi launcher with improved URL detection:
# - empty -> fallback webapp
# - input with scheme -> use as-is
# - domain-like input (alnav.dev) -> prepend https:// (except .home -> http://)
# - IPs and host:port supported
# - otherwise treat as search query
#
# Dependencies: jq, hyprctl, chromium


SEARCH_BASE="https://search.alnav.dev/search?q="
CHROMIUM_DESKTOP="/run/current-system/sw/share/applications/chromium-browser.desktop"
CHROMIUM_DESKTOP_ALT="/run/current-system/sw/share/applications/chromium.desktop"

# App to workspace mapping
declare -A APP_WORKSPACES=(
    ["kitty"]="1"
    ["zen-beta"]="2"
    ["teams-for-linux"]="3"
    ["https://app.element.io"]="3"
)

echo $1
# Check if app is already running and return workspace ID if found
find_running_app() {
    local app_name="$1"
    if command -v jq >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
        hyprctl -j clients | jq -r --arg app "$app_name" '.[] | select(.class // .initialClass | test($app; "i")) | .workspace.id' 2>/dev/null | head -1
    fi
}

# Check if kitty with tmux develop session is running
is_develop_session_running() {
    tmux has-session -t develop 2>/dev/null
}

# Focus existing app in its workspace
focus_app() {
    local app_name="$1"
    local workspace_id="$2"

    if [ -n "$workspace_id" ]; then
        hyprctl dispatch workspace "$workspace_id"
        # Give a moment for workspace switch then focus the app
        sleep 0.2
        hyprctl dispatch focuswindow "class:$app_name"
        return 0
    fi
    return 1
}

find_chromium_exec() {
    local e
    if [ -f "$CHROMIUM_DESKTOP" ]; then
        e=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$CHROMIUM_DESKTOP" 2>/dev/null | head -1)
    fi
    if [ -z "$e" ] && [ -f "$CHROMIUM_DESKTOP_ALT" ]; then
        e=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$CHROMIUM_DESKTOP_ALT" 2>/dev/null | head -1)
    fi
    if [ -z "$e" ]; then
        e=$(command -v chromium || command -v chromium-browser || command -v google-chrome || true)
    fi
    printf '%s' "$e"
}

# Build a proper URL if the input looks like a host/domain/IP (no scheme)
# Returns the URL on stdout, or empty string if input doesn't look like a URL
build_url() {
    local s="$1"
    # if already has http(s) scheme, return as-is
    if [[ "$s" =~ ^https?:// ]]; then
        printf '%s' "$s"
        return 0
    fi

    # Trim trailing and leading whitespace
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    # host part (before first slash)
    local host="${s%%/*}"

    # Regex checks:
    # - IPv4: 1.2.3.4 optionally with :port and optional path
    # - localhost with optional :port
    # - domain-like: token.token (TLD 1+ char allowed, includes .home)
    if [[ "$host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]+)?$ ]] \
       || [[ "$host" =~ ^localhost(:[0-9]+)?$ ]] \
       || [[ "$host" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z0-9-]+(:[0-9]+)?$ ]]; then
        # Choose scheme: .home -> http, else https
        if [[ "$host" == *.home ]]; then
            printf 'http://%s' "$s"
        else
            printf 'https://%s' "$s"
        fi
        return 0
    fi

    # not identified as URL
    printf ''
    return 1
}

# Launch chromium in app mode, with workspace rule
open_chromium_app() {
    local url="$1"
    local chrome_exec="$2"
    local workspace_id="$3"

    if [ -z "$chrome_exec" ]; then
        chrome_exec=$(find_chromium_exec)
    fi
    if [ -z "$chrome_exec" ]; then
        echo "Error: chromium executable not found." >&2
        exit 1
    fi

    if [ -n "$workspace_id" ]; then
        hyprctl dispatch exec "[workspace $workspace_id silent] $chrome_exec --app=\"$url\""
        hyprctl dispatch workspace "$workspace_id"
    else
        exec setsid "$chrome_exec" --app="$url"
    fi
}

# Launch arbitrary app command (with workspace rule)
run_app_cmd() {
    local workspace_id=""

    # Check if first argument is a workspace ID
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        workspace_id="$1"
        shift
    fi

    if [ -n "$workspace_id" ]; then
        hyprctl dispatch exec "[workspace $workspace_id silent] $*"
        hyprctl dispatch workspace "$workspace_id"
    else
        exec "$@"
    fi
}

# Handle opencode special case - create new pane in develop session if it exists
handle_opencode() {
    # Check if any tmux session exists
    if tmux list-sessions >/dev/null 2>&1; then
        local kitty_workspace
        kitty_workspace=$(find_running_app "kitty")

        if [ -n "$kitty_workspace" ]; then
            # Kitty is running somewhere
            if [ "$kitty_workspace" = "1" ]; then
                # Kitty is in workspace 1, go there and create new tmux window
                hyprctl dispatch workspace 1
                sleep 0.2
                hyprctl dispatch focuswindow "class:kitty"

                # Create new window in current tmux session (not forced to develop)
                tmux new-window -c ~ 'CACHE=~/.cache/dev-dirs; [ ! -f "$CACHE" ] && find ~ -name ".git" -type d | sed "s|/.git||" | sort -r > "$CACHE"; cd "$(cat "$CACHE" | fzf --tac)" && exec opencode'
                # Ensure focus stays on kitty after tmux window creation
                sleep 0.2
                hyprctl dispatch focuswindow "class:kitty"
            else
                # Kitty is not in workspace 1, open new kitty in workspace 1
                hyprctl dispatch exec "[workspace 1 silent] kitty -e sh -c 'EDITOR=nvim; CACHE=~/.cache/dev-dirs; [ ! -f \"\$CACHE\" ] && find ~ -name \".git\" -type d | sed \"s|/.git||\" | sort -r > \"\$CACHE\"; cd \"\$(cat \"\$CACHE\" | fzf --tac)\" && exec opencode'"
                hyprctl dispatch workspace 1
                # Focus the newly opened kitty window
                sleep 0.3
                hyprctl dispatch focuswindow "class:kitty"
            fi
            return 0
        fi
    fi

    # Either no tmux session or no kitty running, open new kitty in workspace 1
    hyprctl dispatch exec "[workspace 1 silent] kitty -e sh -c 'EDITOR=nvim; CACHE=~/.cache/dev-dirs; [ ! -f \"\$CACHE\" ] && find ~ -name \".git\" -type d | sed \"s|/.git||\" | sort -r > \"\$CACHE\"; cd \"\$(cat \"\$CACHE\" | fzf --tac)\" && exec opencode'"
    hyprctl dispatch workspace 1
    # Focus the newly opened kitty window
    sleep 0.3
    hyprctl dispatch focuswindow "class:kitty"
}

# Handle btop special case - create new pane in develop session if it exists
handle_btop() {
    # Check if any tmux session exists
    if tmux list-sessions >/dev/null 2>&1; then
        local kitty_workspace
        kitty_workspace=$(find_running_app "kitty")

        if [ -n "$kitty_workspace" ]; then
            # Kitty is running somewhere
            if [ "$kitty_workspace" = "1" ]; then
                # Kitty is in workspace 1, go there and create new tmux window
                hyprctl dispatch workspace 1
                sleep 0.2
                hyprctl dispatch focuswindow "class:kitty"

                # Create new window in current tmux session (not forced to develop)
                tmux new-window -c ~ 'btop'
                # Ensure focus stays on kitty after tmux window creation
                sleep 0.2
                hyprctl dispatch focuswindow "class:kitty"
            else
                # Kitty is not in workspace 1, open new kitty in workspace 1
                hyprctl dispatch exec "[workspace 1 silent] kitty -e btop"
                hyprctl dispatch workspace 1
                # Focus the newly opened kitty window - wait longer for btop to load
                sleep 0.8
                # Try to focus the newest kitty window in workspace 1
                local newest_kitty
                newest_kitty=$(hyprctl -j clients | jq -r '[.[] | select(.workspace.id == 1 and .class == "kitty")] | sort_by(.at) | last | .address' 2>/dev/null)
                if [ -n "$newest_kitty" ] && [ "$newest_kitty" != "null" ]; then
                    hyprctl dispatch focuswindow "address:$newest_kitty"
                else
                    hyprctl dispatch focuswindow "class:kitty"
                fi
            fi
            return 0
        fi
    fi

    # Either no tmux session or no kitty running, open new kitty in workspace 1
    hyprctl dispatch exec "[workspace 1 silent] kitty -e btop"
    hyprctl dispatch workspace 1
    # Focus the newly opened kitty window - wait longer for btop to load
    sleep 0.8
    # Try to focus the newest kitty window in workspace 1
    local newest_kitty
    newest_kitty=$(hyprctl -j clients | jq -r '[.[] | select(.workspace.id == 1 and .class == "kitty")] | sort_by(.at) | last | .address' 2>/dev/null)
    if [ -n "$newest_kitty" ] && [ "$newest_kitty" != "null" ]; then
        hyprctl dispatch focuswindow "address:$newest_kitty"
    else
        hyprctl dispatch focuswindow "class:kitty"
    fi
}

# MAIN
INPUT="$*"
# trim
INPUT="${INPUT#"${INPUT%%[![:space:]]*}"}"
INPUT="${INPUT%"${INPUT##*[![:space:]]}"}"

# find chrome binary early
CHROME_EXEC=$(find_chromium_exec)

# 1) empty -> exit
if [ -z "$INPUT" ]; then
    exit 0
fi

# 1.5) check for opencode special handling
if [[ "$INPUT" == "opencode" ]]; then
    handle_opencode
    exit 0
fi

# 1.6) check for btop special handling
if [[ "$INPUT" == "btop" ]]; then
    handle_btop
    exit 0
fi

# 2) check for workspace-managed apps first
read -r -a TOKENS <<< "$INPUT"
FIRST_TOKEN="${TOKENS[0]}"

# Check if this is a workspace-managed app
if [ -n "${APP_WORKSPACES[$FIRST_TOKEN]}" ]; then
    TARGET_WORKSPACE="${APP_WORKSPACES[$FIRST_TOKEN]}"

    # Check if app is already running
    RUNNING_WORKSPACE=$(find_running_app "$FIRST_TOKEN")

    if [ -n "$RUNNING_WORKSPACE" ]; then
        # App is already running, focus it
        focus_app "$FIRST_TOKEN" "$RUNNING_WORKSPACE"
        exit 0
    else
        # App not running, we'll pass the workspace to the launch functions
        # Set a variable to indicate we should use workspace rule
        USE_WORKSPACE_RULE="$TARGET_WORKSPACE"
    fi
fi

# 3) try to build URL (handles schemeless domains and .home rule)
URL=$(build_url "$INPUT")
if [ -n "$URL" ]; then
    open_chromium_app "$URL" "$CHROME_EXEC" "$USE_WORKSPACE_RULE"
    exit 0
fi

# 4) check for desktop entries

# Look for matching .desktop files in standard locations
DESKTOP_DIRS=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/run/current-system/sw/share/applications"
)

for dir in "${DESKTOP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Look for desktop files that match the input name (case-insensitive)
        while IFS= read -r -d '' desktop_file; do
            if [ -f "$desktop_file" ]; then
                # Check if Name field matches our input (case-insensitive)
                name=$(grep -i "^Name=" "$desktop_file" 2>/dev/null | head -1 | cut -d'=' -f2-)
                if [ -n "$name" ] && [[ "${name,,}" == "${INPUT,,}" ]]; then
                    # Found matching desktop entry, extract and execute the command
                    exec_line=$(grep "^Exec=" "$desktop_file" 2>/dev/null | head -1 | cut -d'=' -f2-)
                    if [ -n "$exec_line" ]; then
                        # Remove field codes like %U, %F, etc.
                        exec_line=$(echo "$exec_line" | sed 's/ %[a-zA-Z]//g')
                        if [ -n "$USE_WORKSPACE_RULE" ]; then
                            run_app_cmd "$USE_WORKSPACE_RULE" bash -c "$exec_line"
                        else
                            run_app_cmd bash -c "$exec_line"
                        fi
                        exit 0
                    fi
                fi
            fi
        done < <(find "$dir" -maxdepth 1 -name "*.desktop" -print0 2>/dev/null)
    fi
done

# 5) check if entire input looks like an executable command
if [[ "$FIRST_TOKEN" == */* && -x "$FIRST_TOKEN" ]] || command -v "$FIRST_TOKEN" >/dev/null 2>&1; then
    if [ -n "$USE_WORKSPACE_RULE" ]; then
        run_app_cmd "$USE_WORKSPACE_RULE" "${TOKENS[@]}"
    else
        run_app_cmd "${TOKENS[@]}"
    fi
    exit 0
fi

# 6) fallback: search query (spaces -> +)
# Check for special search prefixes
if [[ "$INPUT" == "!nix "* ]]; then
    # Remove !nix prefix and search in search.nixos.org
    NIX_QUERY="${INPUT#!nix }"
    NIX_QUERY=$(printf '%s' "$NIX_QUERY" | sed 's/ /+/g')
    open_chromium_app "https://search.nixos.org/packages?query=${NIX_QUERY}" "$CHROME_EXEC" "$USE_WORKSPACE_RULE"
elif [[ "$INPUT" == "!yt "* ]]; then
    # Remove !yt prefix and search on YouTube
    YT_QUERY="${INPUT#!yt }"
    YT_QUERY=$(printf '%s' "$YT_QUERY" | sed 's/ /+/g')
    open_chromium_app "https://www.youtube.com/results?search_query=${YT_QUERY}" "$CHROME_EXEC" "$USE_WORKSPACE_RULE"
else
    QUERY=$(printf '%s ' "${TOKENS[@]}" | sed 's/ $//; s/ /+/g')
    open_chromium_app "${SEARCH_BASE}${QUERY}" "$CHROME_EXEC" "$USE_WORKSPACE_RULE"
fi

