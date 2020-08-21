#!/bin/bash
#set -x

############################################################################################
##
## Script to install the latest Minecraft: Education Edition
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
## Feedback: scbree@microsoft.com

# Define variables

tempfile="/tmp/mee.dmg"
weburl="https://aka.ms/meeclientmacos"
appname="Minecraft Education Edition"
app="minecraftpe.app"
log="/Library/Intune/Scripts/installMinecraftEducationEdition/installmee.log"
processpath="minecraftpe"
VOLUME="/tmp/InstallMEE"
metadir="/Library/Intune/Scripts/installMinecraftEducationEdition"
metafile="$metadir/$appname.meta"
lastmodified=$(curl -sIL "$weburl" | grep -i "last-modified" | awk '{$1=""; print $0}' | awk '{ sub(/^[ \t]+/, ""); print }' | tr -d '\r')
# start logging

exec 1>> $log 2>&1

# Begin Script Body

echo ""
echo "##############################################################"
echo "# $(date) | Starting install of $appname"
echo "############################################################"
echo ""

## Is the app already installed?
if [ -d "/Applications/$app" ]; then

  # App is already installed, we need to determine if it requires updating or not
  echo "$(date) | $appname already installed"

  #If we're running, let's just drop out quietly
  if pgrep -f $processpath; then

    echo "$(date) | $processpath is currently running, nothing we can do here"
    exit 1

  fi

  ## Let's determine when this file we're about to download was last modified
  echo "$(date) | $weburl last update on $lastmodified"

  ## Did we store the last modified date last time we installed/updated?
  if [ -d $metadir ]; then
      echo "$(date) | Meta dir [$metadir] already exists"

      echo "$(date) | Looking for metafile ($metafile)"
      if [ -f "$metafile" ]; then
        previouslastmodifieddate=$(cat "$metafile")
        if [[ "$previouslastmodifieddate" != "$lastmodified" ]]; then
          install="yes"
        else
          echo "$(date) | No update between previous [$previouslastmodifieddate] and current [$lastmodified]"
          exit 0
        fi
      else
        echo "$(date) | Meta file $metafile notfound, downloading anyway"
        install="yes"
      fi

  else

      ## Creating Metadirectory
      echo "$(date) | Creating [$metadir]"
      mkdir -p $metadir

      ## We can't tell if the current version is newer or older, so let's update anyway
      install="yes"
      
  fi

else

  # App isn't installed, lets download and get ready for install
  install="yes"

fi

#check if we're downloading and installing
if [ $install == "yes" ]; then

    #download the file
    echo "$(date) | Downloading $appname"
    curl -L -f -o $tempfile $weburl

    # Mount the dmg file...
    echo "$(date) | Installing $appname"
    hdiutil attach -nobrowse -mountpoint $VOLUME $tempfile

    # Sync the application and unmount once complete
    rsync -a "$VOLUME"/*.app "/Applications/"

    #unmount the dmg
    hdiutil detach -quiet "$VOLUME"

    #checking if the app was installed successfully
    if [ "$?" = "0" ]; then
        if [[ -a "/Applications/$app" ]]; then

            echo "$(date) | $appname Installed"
            echo "$(date) | Cleaning Up"
            rm -rf $tempfile

            if [ -d $metadir ]; then
                echo "$(date) | [$metadir] already exists"
            else
                echo "$(date) | Creating [$metadir]"
                mkdir -p $metadir
            fi

            echo "$(date) | Writing last modifieddate $lastmodified to $metafile"
            echo "$lastmodified" > "$metafile"

            echo "$(date) | Fixing up permissions"
            sudo chown -R root:wheel "/Applications/$app"

            exit 0
        else
            echo "$(date) | Failed to install $appname"
            exit 1
        fi
    else

        # Something went wrong here, either the download failed or the install Failed
        # intune will pick up the exit status and the IT Pro can use that to determine what went wrong.
        # Intune can also return the log file if requested by the admin
        
        echo "$(date) | Failed to install $appname"
        exit 1
    fi

else
    echo "$(date) | Not downloading or installing $appname"
fi
