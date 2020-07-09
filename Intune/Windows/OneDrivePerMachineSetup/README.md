# OneDrive Per Machine Setup - Win32 app

You can wrap this PowerShell script in a Win32 app and deploy it during a Windows deployment so that the first user logging on gets the OneDrive machine wide installer experience. This readme provides some of the key items in a Win32 app you'll need.

## Install command
powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"
## Uninstall command
I haven't written a process for uninstall yet, but you must provide an uninstall command:

powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"

## Detection method

Registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OneDrive

key exists
