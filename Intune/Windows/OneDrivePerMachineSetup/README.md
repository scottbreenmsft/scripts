# OneDrive Per Machine Setup - Win32 app
## Install command
powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"
## Uninstall command
I haven't written a process for uninstall yet, but you must provide an uninstall command:

powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"

## Detection method

Registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OneDrive

key exists
