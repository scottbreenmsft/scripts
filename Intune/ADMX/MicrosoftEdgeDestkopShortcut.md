# Microsoft Edge Desktop Shortcut Control

Edge 83 has provided the capability to control whether or not a desktop shortcut is created for Edge - https://docs.microsoft.com/en-us/deployedge/microsoft-edge-update-policies#createdesktopshortcutdefault. This can be tested in Intune now by deploying the setting as a custom ADMX.

## Create a custom Windows 10 profile

Create a new Windows 10 custom profile - https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-windows-10.

## Create the custom setting to import the ADMX

+ In the custom profile configuration settings, a new OMA-URI setting and enter the following details:

<table><tr><th>Name</th><td>Edge ADMX</td></tr>
<tr><th>OMA-URI</th><td>./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/Windows/Policy/WindowsCustomizationsAdmx</td></tr>
<tr><th>Data Type</th><td>String</td></tr>
<tr><th>Value</th><td>Copy from https://github.com/scottbreenmsft/scripts/blob/master/Intune/ADMX/Custom_Edge.admx</td></tr>
</table>

## Disable the setting

+ In the custom profile configuration settings, a new OMA-URI setting and enter the following details:

<table><tr><th>Name</th><td>Edge ADMX</td></tr>
<tr><th>OMA-URI</th><td>./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/Windows/Policy/WindowsCustomizationsAdmx</td></tr>
<tr><th>Data Type</th><td>String</td></tr>
<tr><th>Value</th><td>&lt;disabled/&gt;</td></tr>
</table>

## Save and assign the profile

+ Save the profile and assign it to the devices you want to prevent the shortcut from being created on. To get the best results, this profile should be applied to the same group as the Microsoft Edge install so that the setting applies before Microsoft Edge is installed.
