#!/usr/bin/env zsh

#echo Cleaning Dock Plist
#rm ~/Library/Preferences/com.apple.dock.plist; killall Dock

#sleep 10

echo dock config: Removing Dock Persistent Apps | tee -a /var/log/install.log
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

echo dock config: Looking for required applications... | tee -a /var/log/install.log

while [[ $ready -ne 1 ]];do

  missingappcount=0

  for i in $dockitems; do
    if [[ -a "$i" ]]; then
      echo "$i found!"
    else
      echo "dock config: $i not installed yet"  | tee -a /var/log/install.log
      let missingappcount=$missingappcount+1

    fi
  done

  echo "dock config:Missing app count is $missingappcount"

  if [[ $missingappcount -eq 0 ]]; then
    ready=1
    echo "dock config: All apps found, lets prep the dock" | tee -a /var/log/install.log
  else
    echo "dock config: Waiting for 60 seconds" | tee -a /var/log/install.log
    sleep 60
  fi


done


for i in $dockitems; do
  echo Looking for "$i" | tee -a /var/log/install.log
  if [[ -a "$i" ]] ; then
    echo dock config: Adding $i to Dock | tee -a /var/log/install.log
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$i</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  fi
done

echo dock config: Enabling Magnification | tee -a /var/log/install.log
defaults write com.apple.dock magnification -boolean YES

echo dock config: Enable Dim Hidden Apps in Dock | tee -a /var/log/install.log
defaults write com.apple.dock showhidden -bool true

#echo Enable Auto Hide dock
#defaults write com.apple.dock autohide -bool true

echo dock config: Enable Minimise Icons into Dock Icons | tee -a /var/log/install.log
defaults write com.apple.dock minimize-to-application -bool yes

echo dock config: Restarting Dock | tee -a /var/log/install.log
killall Dock
