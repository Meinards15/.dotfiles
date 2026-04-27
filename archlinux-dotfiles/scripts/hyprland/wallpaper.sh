#!/bin/bash

BASE="$HOME/Pictures/Wallpapers"
CONF="$HOME/.config/hypr/hyprpaper.conf"
STATE="$HOME/CURRENT"

LAST_THEME=""

while true; do
    # Encontra todas as linhas com WALLPAPER=
    # Pega a última ocorrência (caso tenha várias)
    THEME=$(grep "^WALLPAPER_FILE=" "$STATE" 2>/dev/null | tail -n 1 | cut -d= -f2)

    # Se nada encontrado, apenas espera
    [ -z "$THEME" ] && sleep 1 && continue

    # Se mudou, aplica novo wallpaper
    if [ "$THEME" != "$LAST_THEME" ]; then
        WALL=$(find "$BASE/$THEME" -type f | shuf -n 1)

        echo "
preload = $WALL
wallpaper = ,$WALL
" > "$CONF"

        killall hyprpaper 2>/dev/null
        hyprpaper &

        LAST_THEME="$THEME"
        notify-send "Wallpaper" "Loaded theme: $THEME"
    fi

    sleep 1
done

