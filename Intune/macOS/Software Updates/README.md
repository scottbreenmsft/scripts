# Managing Software Updates for macOS

Software updates on macOS can be managed by Intune using 2 options.

 - [Update policies for macOS](#Update-policies-for-macOS)
   - Uses commands to trigger installation of updates at device check-in or on a schedule.
 - [Configuring Software Updates on macOS](#Configuring-Software-Updates-on-macOS)
   - Configures the built in Software Updates feature on macOS to do things like automatically install updates and delay install of updates for a certain number of days after release
   
## Update policies for macOS
Insert documentation here..
   
## Configuring Software Updates on macOS
macOS allows the deployment of custom profiles to configure settings. Software Updates on macOS can be configured using custom profiles. The list of profiles and settings are available in the [Software Update - Apple Device Management Documentation](https://developer.apple.com/documentation/devicemanagement/softwareupdate).

For information on creating a configuraiton profile, see [Configuring Multiple Devices Using Profiles](https://developer.apple.com/documentation/devicemanagement/configuring_multiple_devices_using_profiles).

### Configure the profile
As an example, to configure and force the following settings:
 - Automatically keep my Mac up-to-date
 - Check for updates
 - Download new updates when available
 - Install macOS updates
 - Install app updates from the App Store
 - Install system data files and security updates
 
 You could use a profile with the following XML:
 - [Custom - Software Updates.mobileconfig](Custom-SoftwareUpdates.mobileconfig)

### Deploy the profile
The custom XML file can then be uploaded to Intune for deployment using a [macOS Custom profile](https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-macos).

### Configure Deferral
You can control how many days after release a software updates is made available to users or installs automatically using [macOS - Device Restrictions](https://docs.microsoft.com/en-us/mem/intune/configuration/device-restrictions-macos#settings-apply-to-user-approved-device-enrollment-automated-device-enrollment-supervised).
