#!/bin/bash
# Wallpaper setter for hyprpaper
# Requires hyprpaper to be running with config at ~/.config/hypr/hyprpaper.conf

WALLPAPER="$1"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: $0 <wallpaper-path>"
    exit 1
fi

# Update hyprpaper config
echo "preload = $WALLPAPER
wallpaper = eDP-1,$WALLPAPER
splash = false" > "$HYPRPAPER_CONF"

# Tell hyprpaper to reload config
# Try sending SIGUSR1 to reload
pkill -USR1 hyprpaper 2>/dev/null

# Alternative: restart hyprpaper (slower but more reliable)
killall hyprpaper 2>/dev/null
sleep 0.2
hyprpaper &