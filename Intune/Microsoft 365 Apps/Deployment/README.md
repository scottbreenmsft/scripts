**under construction**

# Microsoft 365 App Deployment using Win32 apps

This article provides information about how to deploy Microsoft 365 Apps (including optional apps for Visio and Project) using an Intune Win32 app. 

**Why not use the built in Microsoft 365 Apps deployment?**

The Microsoft 365 Apps built-in to Microsoft Endpoint Manager the [Office CSP](https://docs.microsoft.com/en-us/windows/client-management/mdm/office-csp) in Windows which does not have logic to handle the targetting of more than one installation. This is relevant if you have a base install for Microsoft 365 Apps on a device but want to provide optional or more targetted installation of slight variations like adding Visio Standard, Project Professional, etc. In addition, the Office CSP does not have any user interaction capabiltiies. This is important because the installation of Office cannot be changed while any Office app is open, using the [Office CSP](https://docs.microsoft.com/en-us/windows/client-management/mdm/office-csp) you have the option of force closing the apps or failing if the apps are open.

| Feature | Built in tool | Custom Win32 app | 
|---|---|---|
| User interaction | No | Yes |
| Optional additional apps | No | Yes |
| Force close apps | Yes | Yes |

## Using Service UI to display user notifications

ServiceUI.exe is a process that is used by Microsoft Deployment Toolkit or Configuration Manager to display notifications in the user context during a task sequence deployment. You can find a copy of ServiceUI.exe in the installed program files for Microsoft Deployment Toolkit under **C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe**.

I've created two scripts in this repository for you to start with:
 - **Use-ServiceUI.ps1** - Is the wrapper script that runs ServiceUI and executes a command in the user context if a user is logged on and then runs the install command.
 - **Notification.ps1** - Is the script that ServiceUI will run to interact with the user (in this case to prompt to close Office apps).

If you want to run something other than notification.ps1 you can edit Use-ServiceUI.ps1 to change which process it runs if a user is logged on.

### Creating the Win32 app
The script takes the parameter **InstallCommand** which is the command you would normally enter as the install command.

- **Example command line**: powershell.exe -executionpolicy bypass -file Use-ServiceUI.ps1 -installcommand "setupodt.exe /configure Add-VisioStdXVolume-x64.xml"
- **Detection Method**: See https://github.com/scottbreenmsft/scripts/edit/master/Intune/Microsoft%20365%20Apps/Detection
