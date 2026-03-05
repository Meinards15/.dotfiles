#!/bin/bash
# File: bluetui_focus.sh

# Run bluetui in background
bluetui &

# Store PID
PID=$!

# Watch for focus loss using hyprctl
while kill -0 $PID 2>/dev/null; do
    FOCUS=$(hyprctl activewindow | grep 'class: local.bluetui')
    if [ -z "$FOCUS" ]; then
        kill $PID
        exit
    fi
    sleep 0.05
done

