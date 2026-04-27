#!/usr/bin/env bash
# Minimal Media Control for Hyprland Keybinds
# Stores state in ~/media-control

set -euo pipefail

VAR_FILE="$HOME/media-control"


default="spotify"

if [[ ! -s "$VAR_FILE" ]]; then
    echo "CURRENT_PLAYER=$default" >> "$VAR_FILE"
    echo "PREV_PLAYER=$default" >> "$VAR_FILE"
fi


CURRENT_PLAYER="$(grep -m1 '^CURRENT_PLAYER=' "$VAR_FILE" 2>/dev/null | cut -d'=' -f2-)"
PREV_PLAYER="$(grep -m1 '^PREV_PLAYER=' "$VAR_FILE" 2>/dev/null | cut -d'=' -f2-)"


## echo "$CURRENT_PLAYER"


check_player() {
    local found="$(playerctl --list-all 2>/dev/null | xargs -I{} bash -c '
        if [[ "$(playerctl --player="{}" status 2>/dev/null)" == "Playing" ]]; then
            echo "{}"
            exit 0
        fi
    ' || true)"


    if [[ -n "$found" ]]; then
	
        CURRENT_PLAYER="$found"
        echo "$CURRENT_PLAYER"
        return 0
    fi

    
    echo "$PREV_PLAYER"
    return 1
}

check_player


player_cmd() {
    playerctl --player="$CURRENT_PLAYER" "$1" &>/dev/null
}

current() {
    echo "=== Media Control Status ==="
    echo "Variable File: $VAR_FILE"
    echo "Current Player: $(CURRENT_PLAYER)"
    echo "Previous Player: $(PREV_PLAYER)"
    
    local player="$(get_active_player)"
    if [[ -n "$player" ]]; then
        echo "Status: $(playerctl --player="$player" status 2>/dev/null || echo 'Unknown')"
        playerctl --player="$player" metadata --format '{{artist}} - {{title}}' 2>/dev/null || true
    fi
}





case "${1:-}" in
    play-pause)   player_cmd "play-pause" ;;
    play)         player_cmd "play" ;;
    pause)        player_cmd "pause" ;;
    next)         player_cmd "next" ;;
    prev)         player_cmd "previous" ;;
    stop)         player_cmd "stop" ;;
    
    up)     pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    mute)             pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    set-volume)       pactl set-sink-volume @DEFAULT_SINK@ "${2:-50}%" ;;
    
    switch)       switch_player "${2:-}" ;;
    
    status)   current ;;
    
    *)
        exit 1
        ;;
esac
