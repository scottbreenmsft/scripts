#!/usr/bin/env zsh

#echo Cleaning Dock Plist
#rm ~/Library/Preferences/com.apple.dock.plist; killall Dock

#sleep 10

echo dock config: Removing Dock Persistent Apps | tee -a ~/library/Logs/script-dock.log


dockitems=( "/Applications/Microsoft Edge.app"
            "/Applications/Microsoft Outlook.app"
            "/Applications/Microsoft Word.app"
            "/Applications/Microsoft Excel.app"
            "/Applications/Microsoft Teams.app"
            "/Applications/Microsoft PowerPoint.app"
            "/Applications/Microsoft OneNote.app"
	    "/Applications/Company Portal.app"
            "/System/Applications/App Store.app"
            "/System/Applications/System Preferences.app")

echo dock config: Looking for required applications... | tee -a ~/library/Logs/script-dock.log

while [[ $ready -ne 1 ]];do

  missingappcount=0

  for i in $dockitems; do
    if [[ -a "$i" ]]; then
      echo "$i found!"
    else
      echo "dock config: $i not installed yet"  | tee -a ~/library/Logs/script-dock.log
      let missingappcount=$missingappcount+1

    fi
  done

  echo "dock config:Missing app count is $missingappcount"

  if [[ $missingappcount -eq 0 ]]; then
    ready=1
    echo "dock config: All apps found, lets prep the dock" | tee -a ~/library/Logs/script-dock.log
  else
    echo "dock config: Waiting for 60 seconds" | tee -a ~/library/Logs/script-dock.log
    sleep 60
  fi


done

echo dock config: Clearing Dock | tee -a ~/library/Logs/script-dock.log
defaults delete ~/Library/Preferences/com.apple.dock persistent-apps
defaults delete ~/Library/Preferences/com.apple.dock persistent-others


for i in $dockitems; do
  echo Looking for "$i" | tee -a ~/library/Logs/script-dock.log
  if [[ -a "$i" ]] ; then
    echo dock config: Adding $i to Dock | tee -a ~/library/Logs/script-dock.log
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$i</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  fi
done

echo dock config: Enabling Magnification | tee -a ~/library/Logs/script-dock.log
defaults write com.apple.dock magnification -boolean YES

echo dock config: Enable Dim Hidden Apps in Dock | tee -a ~/library/Logs/script-dock.log
defaults write com.apple.dock showhidden -bool true

#echo Enable Auto Hide dock
#defaults write com.apple.dock autohide -bool true

echo dock config: Enable Minimise Icons into Dock Icons | tee -a ~/library/Logs/script-dock.log
defaults write com.apple.dock minimize-to-application -bool yes

echo dock config: Restarting Dock | tee -a ~/library/Logs/script-dock.log
killall Dock

