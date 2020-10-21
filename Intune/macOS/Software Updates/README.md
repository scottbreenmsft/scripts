# Managing Software Updates for macOS

Software updates on macOS can be managed by Intune using 2 options.

 - [Update policies for macOS](#Update-policies-for-macOS)
   - Uses commands to trigger installation of updates at device check-in or on a schedule.
 - [Configuring Software Updates on macOS](#Configuring-Software-Updates-on-macOS)
   - Configures the built in Software Updates feature on macOS to do things like automatically install updates and delay install of updates for a certain number of days after release
   
## Update policies for macOS
Insert documentation here..
   
## Configuring Software Updates on macOS
macOS allows the deployment of custom profiles. The list of profiles and settings are available in the [Software Update - Apple Device Management Documentation](https://developer.apple.com/documentation/devicemanagement/softwareupdate).

As an example, to configure adn force the following settings:
 - Automatically keep my Mac up-to-date
 - Check for updates
 - Download new updates when available
 - Install macOS updates
 - Install app updates from the App Store
 - Install system data files and security updates
 
 You could use a profile with the following XML:
 

The custom XML file can then be uploaded to Intune for deployment using a [macOS Custom profile](https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-macos).
