# Minecraft: Education Edition Installation Script

This script is an example to show how to use [Intune Shell Scripting](https://docs.microsoft.com/en-us/mem/intune/apps/macos-shell-scripts) to install DMG applications. In this example the script will download the Minecraft Education Edition dmg file from the Microsoft download servers (https://aka.ms/meeclientmacos) and then install it onto the Mac.

## Scenarios
The script can be used for two scenarios:

 - Install - The script can be used to install Minecraft: Education Edition
 
 - Update - The script can run once or scheduled to update the installed version of Minecraft: Education Edition. You can schedule the script to run once a week to check for updates.

## Description

The script performs the following actions if **Minecraft Education Edition** is not already installed:
1. Downloads the DMG from **https://aka.ms/meeclientmacos** to **/tmp/mee.dmg**.
2. Mounts the DMG file at **/tmp/InstallMEE**.
3. Copies (installs) the application to the **/Applications** directory.
4. Unmounts the DMG file.
5. Deletes the DMG file.
6. Records the date-modified attribute of **https://aka.ms/meeclientmacos** so it can be checked at future script executions.

If **Minecraft Education Edition** is already installed, it will compare the date-modified of **https://aka.ms/meeclientmacos** against the recorded version. 
 - If the date-modified of **https://aka.ms/meeclientmacos** is newer, it will download and install the new version.
 - If no date-modified was previously recorded, it will download and attempt to install.

## Script Settings

- Run script as signed-in user : No
- Hide script notifications on devices : Yes
- Script frequency : 
  - **Not configured** to run once
  - **Every 1 week** to check for and install updates once a week
- Number of times to retry if script fails : 3

## Log File

The log file will output to **/Library/Intune/Scripts/installMinecraftEducationEdition/installmee.log** by default. Exit status is either 0 or 1. To gather this log with Intune remotely take a look at [Troubleshoot macOS shell script policies using log collection](https://docs.microsoft.com/en-us/mem/intune/apps/macos-shell-scripts#troubleshoot-macos-shell-script-policies-using-log-collection).
```
Log here
```
