#!/bin/bash
FILE="$1"
hyprctl hyprpaper preload "$FILE"
hyprctl hyprpaper wallpaper "eDP-1,$FILE"
hyprctl hyprpaper unload unused