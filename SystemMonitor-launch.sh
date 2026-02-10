#!/bin/bash
# Launches System Monitor (tmux dashboard) in gnome-terminal.
# Window size: 70% of screen with 15% margin on all sides (top, bottom, left, right).

MONITOR_SCRIPT="${HOME}/.local/bin/SystemMonitor.sh"
TITLE="System Monitor"

# Get screen size
W=1920
H=1080
if command -v xdotool &>/dev/null; then
    read -r W H < <(xdotool getdisplaygeometry 2>/dev/null) || true
else
    read -r W H < <(xrandr 2>/dev/null | grep -oP 'current \d+ x \d+' | head -1 | sed 's/current \([0-9]*\) x \([0-9]*\)/\1 \2/') || true
fi
[[ -z "${W:-}" || ! "$W" =~ ^[0-9]+$ ]] && W=1920
[[ -z "${H:-}" || ! "$H" =~ ^[0-9]+$ ]] && H=1080

# 70% width and height; 15% margin each side (15+70+15=100)
WIN_W=$((W * 70 / 100))
WIN_H=$((H * 70 / 100))
POS_X=$((W * 15 / 100))
POS_Y=$((H * 15 / 100))

# Open with modest geometry so it never opens fullscreen; wmctrl will set exact size/position
gnome-terminal --class=SystemMonitor --title="$TITLE" --geometry=100x30 -- bash -c "\"${MONITOR_SCRIPT}\"; exec bash" &
TERM_PID=$!

# Apply 70% size and centered position (15% margins) as soon as window exists
if command -v wmctrl &>/dev/null; then
    for _ in $(seq 1 50); do
        wmctrl -r "$TITLE" -e 0,$POS_X,$POS_Y,$WIN_W,$WIN_H 2>/dev/null && break
        sleep 0.1
    done
fi

wait $TERM_PID
