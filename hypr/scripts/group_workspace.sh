#!/usr/bin/env bash
# hypr_group_workspace.sh
# Groups all windows in the current Hyprland workspace into a single tab group.

set -euo pipefail

# ── 1. Sanity check ────────────────────────────────────────────────────────────
if ! command -v hyprctl &>/dev/null; then
  echo "Error: hyprctl not found. Are you running Hyprland?" >&2
  exit 1
fi

# ── 2. Get current workspace ID ────────────────────────────────────────────────
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')
echo "Active workspace: $CURRENT_WS"

# ── 3. Collect all window addresses on this workspace ─────────────────────────
mapfile -t ADDRESSES < <(
  hyprctl clients -j \
    | jq -r --argjson ws "$CURRENT_WS" \
        '.[] | select(.workspace.id == $ws) | .address'
)

COUNT=${#ADDRESSES[@]}

if [[ $COUNT -eq 0 ]]; then
  echo "No windows found on workspace $CURRENT_WS."
  exit 0
fi

if [[ $COUNT -eq 1 ]]; then
  echo "Only one window on workspace $CURRENT_WS — nothing to group."
  exit 0
fi

echo "Found $COUNT windows. Grouping them..."

# ── 4. Focus and toggle-group the first window (creates the group) ─────────────
FIRST="${ADDRESSES[0]}"
hyprctl dispatch focuswindow "address:$FIRST"
sleep 0.1
hyprctl dispatch togglegroup

echo "  [1/$COUNT] Created group from window $FIRST"

# ── 5. Move every remaining window into the group ─────────────────────────────
# moveintogroup requires a direction — try all four until one succeeds.
move_into_group() {
  for dir in l r u d; do
    result=$(hyprctl dispatch moveintogroup "$dir" 2>&1)
    if [[ "$result" == "ok" ]]; then
      return 0
    fi
  done
  echo "  Warning: could not move window into group (no adjacent group found in any direction)" >&2
  return 1
}

for i in "${!ADDRESSES[@]}"; do
  [[ $i -eq 0 ]] && continue          # already grouped above
  ADDR="${ADDRESSES[$i]}"
  hyprctl dispatch focuswindow "address:$ADDR"
  sleep 0.1
  if move_into_group; then
    echo "  [$((i+1))/$COUNT] Moved window $ADDR into group"
  fi
done

# ── 6. Focus the group's first tab so the user lands somewhere sensible ────────
hyprctl dispatch focuswindow "address:$FIRST"

echo ""
echo "Done — $COUNT windows grouped on workspace $CURRENT_WS."
