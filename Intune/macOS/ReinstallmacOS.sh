#!/bin/bash
set -x

# Re-install current build of macOS
ver=$(sw_vers | grep ProductVersion | cut -d':' -f2 | tr -d ' ')

# Download and install specific version of Catalina
#ver="10.15.6"

echo "Downloading Operating System"
#/usr/sbin/softwareupdate --fetch-full-installer  --full-installer-version $ver
/usr/sbin/softwareupdate --fetch-full-installer

echo "installing OS"
#'/Applications/Install macOS Monterey.app/Contents/Resources/startosinstall' --eraseinstall --agreetolicense --forcequitapps --newvolumename 'Macintosh HD' --nointeraction --passprompt
