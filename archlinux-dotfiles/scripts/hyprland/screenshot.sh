#!/bin/bash
FILENAME="$HOME/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
grim -g "$(slurp)" "$FILENAME"
wl-copy < "$FILENAME"
notify-send "Screenshot" "Saved to $FILENAME"

