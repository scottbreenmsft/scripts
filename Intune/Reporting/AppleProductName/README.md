# Apple Product Name Report
As of the 2207 release of Intune, the [Product Name](https://support.apple.com/en-au/guide/deployment/depa9e8e14a4/web) attribute is now collected for iOS and macOS. This information can be viewed per device in the Microsoft Endpoint Manager admin console, of can be retrieved for all iOS and macOS devices using a script that interacts with Graph. 

This script provides a sample of the code you could use to retrieve a list of iOS and macOS devices and their Product Name value. 

The script also filters the returned results and removes duplicate entries by serial number based on last sync time. By default the script exports to the current directory export.csv.
