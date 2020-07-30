# Minecraft Education Edition Installation Script

This script is an example to show how to use [Intune Shell Scripting](https://docs.microsoft.com/en-us/mem/intune/apps/macos-shell-scripts) to install applications. In this case the script will download the Minecraft Education Edition dmg file from the Microsoft download servers (https://aka.ms/meeclientmacos) and then install it onto the Mac.

## Description

The script performs the following actions if **Minecraft Education Edition** is not already installed:
1. Downloads the DMG from **https://aka.ms/meeclientmacos** to **/tmp/mee.dmg**.
2. Mounts the DMG file at **/tmp/InstallMEE**.
3. Copies (installs) the application to the **/Applications** directory.
4. Unmounts the DMG file.
5. Deletes the DMG file.

## Log

The script writes to the log file **/var/log/installmee.log**.

## Script Settings

- Run script as signed-in user : No
- Hide script notifications on devices : Yes
- Script frequency : Not configured
- Number of times to retry if script fails : 3
