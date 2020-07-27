#!/bin/bash
#set -x

############################################################################################
##
## Script to download and install the latest Minecraft: Education Education for maCOS
##
###########################################

## Copyright (c) 2020 Microsoft Corp. All rights reserved.
## Scripts are not supported under any Microsoft standard support program or service. The scripts are provided AS IS without warranty of any kind.
## Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a
## particular purpose. The entire risk arising out of the use or performance of the scripts and documentation remains with you. In no event shall
## Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
## (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary
## loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility
## of such damages.

# Define variables
tempfile="/tmp/mee.dmg"
weburl="https://aka.ms/meeclientmacos"
appname="Minecraft: Education Edition"
app="minecraftpe.app"
log="/var/log/installmee.log"
VOLUME="/tmp/InstallMEE"

# start logging

exec 1>> $log 2>&1

if [[ -a "/Applications/$app" ]]; then
  echo "$(date) | $appname already installed, nothing to do here"
  exit 0
else
# Begin Script Body

   echo ""
   echo "##############################################################"
   echo "# $(date) | Starting install of $appname"
   echo "############################################################"
   echo ""

   # Let's download the files we need and attempt to install...
   echo "$(date) | Downloading $appname"
   curl -L -f -o $tempfile $weburl

   # Mount the dmg file...
   echo "$(date) | Installing $appname"
   hdiutil attach -nobrowse -mountpoint $VOLUME $tempfile

    # Sync the application and unmount once complete
    (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    hdiutil detach -quiet "$VOLUME"; exit $? || exit "$SYNCED")

   if [ "$?" = "0" ]; then
      echo "$(date) | $appname Installed"
      echo "$(date) | Cleaning Up"
      rm -rf $tempfile
      exit 0
   else

   # Something went wrong here, either the download failed or the install Failed
   # intune will pick up the exit status and the IT Pro can use that to determine what went wrong.
   # Intune can also return the log file if requested by the admin
      echo "$(date) | Failed to install $appname"
      exit 1
   fi

fi
