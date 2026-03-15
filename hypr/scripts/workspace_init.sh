#!/usr/bin/env bash
hyprctl dispatch exec "[workspace 1 silent] kitty -e tmux"
hyprctl dispatch exec "[workspace 2 silent] zen"
hyprctl dispatch exec "[workspace 3 silent] element-desktop"
