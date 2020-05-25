#!/bin/bash
START='/Applications/Install macOS Catalina.app/Contents/Resources/startosinstall'

echo "Looking for OS Installer"
if test -f "$START"; then
    echo "startosinstall exists, let's use it"
  else
    echo "Downloading Operating System"
    sudo /usr/sbin/softwareupdate --fetch-full-installer
fi

echo "Beginning New Install"
sudo '/Applications/Install macOS Catalina.app/Contents/Resources/startosinstall' --eraseinstall --agreetolicense --forcequitapps --newvolumename 'Macintosh HD'
