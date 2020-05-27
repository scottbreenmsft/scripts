#!/bin/bash


# this script should be run as user.


echo "Downloading Wallpaper"
curl -L -o ~/Wallpaper.jpg 'https://mail.numberwang.net/backgrounds/macWallpaper.jpg'

echo "Setting Wallpaper"
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "~/Wallpaper.jpg"'
