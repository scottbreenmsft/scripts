#!/usr/bin/env zsh

#echo Cleaning Dock Plist
#rm ~/Library/Preferences/com.apple.dock.plist; killall Dock

#sleep 10

echo Removing Dock Persistent Apps
defaults delete ~/Library/Preferences/com.apple.dock persistent-apps
defaults delete ~/Library/Preferences/com.apple.dock persistent-others

dockitems=( "/Applications/Microsoft Edge.app"
            "/Applications/Microsoft Outlook.app"
            "/Applications/Microsoft Word.app"
            "/Applications/Microsoft Excel.app"
            "/Applications/Microsoft Teams.app"
            "/Applications/Microsoft PowerPoint.app"
            "/Applications/Microsoft OneNote.app"
	          "/Applications/Company Portal.app"
            "/System/Applications/App Store.app"
            "/System/Applications/Utilities/Terminal.app"
            "/System/Applications/System Preferences.app")

echo Looking for required applications...

while [[ $ready -ne 1 ]];do

  missingappcount=0

  for i in $dockitems; do
    if [[ -a "$i" ]]; then
      echo "$i found!"
    else
      echo "$i not installed yet"
      let missingappcount=$missingappcount+1

    fi
  done

  echo "Missing app count is $missingappcount"

  if [[ $missingappcount -eq 0 ]]; then
    ready=1
    echo "All apps found, lets prep the dock"
  else
    echo "Waiting for 60 seconds"
    sleep 60
  fi


done


for i in $dockitems; do
  echo Looking for "$i"
  if [[ -a "$i" ]] ; then
    echo Adding $i to Dock
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$i</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  fi
done

echo Enabling Magnification
defaults write com.apple.dock magnification -boolean YES

echo Enable Dim Hidden Apps in Dock
defaults write com.apple.dock showhidden -bool true

#echo Enable Auto Hide dock
#defaults write com.apple.dock autohide -bool true

echo Enable Minimise Icons into Dock Icons
defaults write com.apple.dock minimize-to-application -bool yes

echo Restarting Dock
killall Dock
