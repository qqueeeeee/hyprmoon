#!/bin/bash
# Apply $1 as the wallpaper for every connected Hyprland monitor via
# `hyprctl hyprpaper wallpaper` (which auto-loads the file in
# hyprpaper >=0.8), then rewrite ~/.config/hypr/hyprpaper.conf so the
# choice survives a reboot. No daemon restart.

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Usage: $0 <wallpaper-path>" >&2
    exit 1
fi

CONF="$HOME/.config/hypr/hyprpaper.conf"

# Start hyprpaper if it isn't running (normally Hyprland autostarts it).
if ! pgrep -x hyprpaper >/dev/null; then
    setsid hyprpaper >/dev/null 2>&1 < /dev/null &
    disown 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        hyprctl hyprpaper listactive >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

# Monitor names from `hyprctl -j monitors`. Anchor on the 4-space indent
# of the top-level monitor object so we don't grab the nested
# "activeWorkspace": { "name": "1" } field.
mapfile -t MONITORS < <(hyprctl -j monitors 2>/dev/null \
    | grep -oP '^    "name"\s*:\s*"\K[^"]+')
if [ "${#MONITORS[@]}" -eq 0 ]; then
    MONITORS=("eDP-1")
fi

tmp="$(mktemp)"
{
    echo "preload = $FILE"
    for m in "${MONITORS[@]}"; do
        hyprctl hyprpaper wallpaper "$m,$FILE" >/dev/null 2>&1
        echo "wallpaper = $m,$FILE"
    done
    echo "splash = false"
} > "$tmp"
mv "$tmp" "$CONF"
