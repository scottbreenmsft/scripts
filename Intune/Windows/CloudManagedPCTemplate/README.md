# [Under Construction] Windows Cloud Managed PC Getting Started Template

This page provides some recommendations for creating your first Windows cloud managed PC configuration in Intune.

## Apps
 - OneDrive machine install
   - Installing OneDrive as a machine based install improves the time from a users first logon to OneDrive being configured because the OneDrive client is installed and updated once per machine and the initial update and setup does not need to occur on first user logon. See https://github.com/scottbreenmsft/scripts/tree/master/Intune/Windows/OneDrivePerMachineSetup.
 - Offline apps
   - Selecting to add Offline apps from the Microsoft Store for Education/Business allows you to deploy the application the device context. When an app is installed in the device context it does not need to install in each users profile at first logon. This improves first logon time and the time from logon to when the app can be used for the first time.
 - Remove built in apps
   - Removing built in apps decreases initial log on time and provides a clean Windows experience. See https://github.com/scottbreenmsft/scripts/tree/master/Intune/Windows/RemoveApps for an example.

## Settings
### Administrative Templates
**Mirosoft OneDrive**
 - Configure OneDrive to sign in automatically
   - Microsoft OneDrive > Silently sign in users to the OneDrive sync app with their Windows credentials > **Enabled**
 - Configure Known Folder Move
   - Microsoft OneDrive > Silently move Windows known folders to OneDrive > **Enabled**
     - Navigate to aad.portal.azure.com to get the Azure AD tenant ID and paste it in.

**Microsoft Edge**
 - Configure Edge to skip the first run experience and go straight to the home page
   - Microsoft Edge > Hide the first-run experience and splash screen > **Enabled**
 - Enable Sync
   - Microsoft Edge > Force synchronization and do not show the sync consent prompt > **Enabled**
 - Disable Edge Desktop Shortcut
   - Microsoft Edge Update > Applications > Prevent Desktop Shortcut creation upon install default > **Disabled**
 
Other settings to consider:
 - Configure Internet Explorer integration
 - Control which extensions are installed silently
 - Configure list of force-installed Web Apps

**Outlook auto configuration**
 - User Configuration > Microsoft Outlook 2016 > Account Settings > Exchange > Automatically configure only the first profile based on Active Directory primary SMTP address > **Enabled**
	
### Device Restrictions
 - **Azure Active Directory preferred tenant domain**
   - This simplfies Windows logon after enrollment. You can specify the domain name Windows should append to usernames when logging on.
     - Device Restrictions > Password > Preferred Azure AD tenant domain > **your fully qualified domain name**

 - **Turn off Consumer Features**
   - This prevents Windows from reaching out and downloading "suggested" applications to keep a clean experience.
     - Device Restrictions > Windows Spotlight > Consumer Features > **Block**

 - Tenant lockdown
### Custom

#### Restrict the private store in the machine context
This configuration ensures that the Store app is restricted to the Private Store and has no dependency on user synchronisation as new, guest or user accounts with no Azure AD presence log on.
Property | Value
---|---
OMA-URI | ./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/RequirePrivateStoreOnly
Type |  Integer
Value | 1

#### Turn off the first sign-in animation
This configuration remove the sign animation so that the user is just presented with the spinning wheel and "Preparing Windows".
Property | Value
---|---
OMA-URI | ./Device/Vendor/MSFT/Policy/Config/WindowsLogon/EnableFirstLogonAnimation
Type |  Integer
Value | 0

#### Disable user Enrollment Status Page (for self deploying mode)
Property | Value
---|---
OMA-URI | ./Vendor/MSFT/DMClient/Provider/ProviderID/FirstSyncStatus/SkipUserStatusPage
Type |  Boolean
Value | True

#### Restricted Groups / LocalUsersAndGroups
If different Local Administrators are required for groups of devices, this CSP can be used to target Azure AD groups as local administrators from Windows 10 20H2. RestrictedGroups is required for versions of Windows prior to 20H2.
https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-localusersandgroups

### Delivery Optimisation 
Use DHCP options for dynamic site based connections

## Admin Units
LAPS/lockdown

## Windows Hello for Business
### SSO to on premises resources
 - Windows Hello Hybrid - https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cert-trust-prereqs
 
### Configure Windows Hello for Business as optional
The following registry key can be set using a PowerShell script to prevent Windows from forcing Windows Hello registration at sign in. This allows Windows Hello to be enabled but not be forced. This could be relevent for students or teachers.

```
Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork
Name: DisablePostLogonProvisioning
Type: DWORD
Value: 1

Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork
Name: Enabled
Type: DWORD
Value: 1
```

### Disable Windows Hello for Business and enabled selectively by group
 - Disable tenant settings (Devices > Enrollment > Windows Hello for Business
 - Use **Identity Protection** profiles to target and enable

## Updates
Windows Update Configuration

How to apply config so it doesn't interrupt AP? OMA-URI?

 - http://aka.ms/WindowsReleaseHealth
 - http://aka.ms/updatevelocity
 - https://techcommunity.microsoft.com/t5/windows-it-pro-blog/optimize-on-premises-monthly-update-delivery-using-the-cloud/ba-p/1483519

Windows 10 Feature Updates

## Endpoint Analytics / Reporting
Intune data collection policy: enable Windows Updates

## Autopilot
### Group setup

Some example dynamic group queries:
 - A group of all Windows corporate devices that are not in Autopilot:
   - -not(device.devicePhysicalIds -any (_ -contains "[ZTDId]")) -and (device.deviceOSType -contains "Windows") -and (device.deviceOwnership -contains "Company")
 - A group of Autopilot devices that have a Group Tag that contains a particular string (e.g. school code). Replace 10001 with your string.
   - (device.devicePhysicalIds -any _ -match "\\\[OrderID\\\]:+.\*10001.\*")

Autopilot Config
Groups - https://docs.microsoft.com/en-us/mem/autopilot/enrollment-autopilot#create-an-autopilot-device-group

### Importing a hardware hash
```
Install-Script Get-WindowsAutoPilotInfo
Get-WindowsAutoPilotInfo -online -grouptag "test"
```

### Troubleshooting
```
Install-Script Get-AutopilotDiagnostics
Get-AutopilotDiagnostics
```
