# Microsoft 365 Apps Detection Script

Use this script to detect an installation of Microsoft 365 apps when deployed using the Office Deployment Tool wrapped in an Intune Win32 app.

## Script Usage
Modify the variables at the start of the script as per your requirements.
 - **ProductReleaseID** - The product you want to check for. For a list, see https://docs.microsoft.com/en-us/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run

 - **Platform** - The platform you expect to be installed. x64 or x86.

 - **ExcludedApps** - The list of apps to exclude from installation when installing O365ProPlusRetail. For a list of options, see https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options#id-attribute-part-of-excludeapp-element.
 
### Excluded Apps
The list of apps to exclude from installation when installing O365ProPlusRetail. For a list of options, see https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options#id-attribute-part-of-excludeapp-element.

**NOTE This is only checked when the product ID is O365ProPlusRetail**

 - For example, if you excluded the installation of groove and teams, the entry would look like this:
   - $ExcludedApps=@("groove","teams")
 - If you only excluded groove, the entry would look like this:
   - $ExcludedApps=@("groove")

## Examples

To check for Visio Standard x64:
```
$ExcludedApps=@()
$ProductID="VisioStdXVolume"
$Platform="x64"
```

To check for Microsoft 365 Apps enterprise x64 with Lync, OneDrive, Groove and Bing excluded:
```
$ExcludedApps=@("groove","lync","OneDrive","Bing")
$ProductID="O365ProPlusRetail"
$Platform="x64"
```
