# Example Software Updates custom configuration

This custom configuration file configures macOS Software Updates to:
 - Automatically keep my Mac up-to-date
 - Automatillcay Check for updates
 - Download new updates when available
 - Install the following updates automatically:
   - macOS updates
   - Install app updates from the App Store
   - Install system data files and security updates
   
See [Device Management Profile - Software Update](https://developer.apple.com/documentation/devicemanagement/softwareupdate) for details.

## Other profile details
The profile contains the following attributes which can be edited as required or desired:

 - **PayloadDisplayName**: macOS - Software Updates
 - **PayloadIdentifier**: com.custom.SoftwareUpdates
 - **PayloadUUID**: 20285685-7DBD-4830-B4F8-57E118BBEC0A
 - **PayloadVersion**: 1
 
See [Device Management Profile - TopLevel](https://developer.apple.com/documentation/devicemanagement/toplevel) for details.
 
The profile contains the following attributes which cannot be edited:
 - **PayloadType**: Configuration
