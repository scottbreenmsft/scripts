# OneDrive Per Machine Setup - Win32 app

You can wrap this PowerShell script in a Win32 app and deploy it during a Windows deployment so that the first user logging on gets the OneDrive machine wide installer experience. This readme provides some of the key items in a Win32 app you'll need. The reason I choose a Win32 app over a PowerShell script is that you can ensure this blocks the Enrollment Status Page from continuing and ensures that no other apps try to install at the same time causing app install conflicts (and failures).

[Intune Standalone - Win32 app management](https://docs.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management).

[OneDrive Per Machine Installation](https://docs.microsoft.com/en-us/onedrive/per-machine-installation#:~:text=Deployment%20instructions.%201%20Download%20OneDriveSetup.exe.%202%20Run%20%22OneDriveSetup.exe,by%20using%20Microsoft%20Endpoint%20Configuration%20Manager%20...%20)

## Install command
powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"
## Uninstall command
I haven't written a process for uninstall yet, but you must provide an uninstall command:

powershell.exe -executionpolicy bypass -command ".\OneDriveSetupMachineInstall.ps1"

## Detection method

- Registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OneDrive
- key exists
- Associated with a 32-bit app on 64-bit clients: Yes
