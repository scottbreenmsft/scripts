<#
.COPYRIGHT
    Licensed under the MIT license.
    See LICENSE in the project root for license information.

.SYNOPSIS
    Remove built-in apps (modern apps) from Windows 10.

.DESCRIPTION
    For info, see 

.EXAMPLE
    .\RemoveWin10Apps.ps1

.NOTES
    FileName:    RemoveWin10Apps.ps1
    Author:      Scott Breen

    Version history:
    0.1 - Initial script updated with help section and a fix for randomly freezing

#>

# List of apps to remove
$AppsToRemove = @(
    "Microsoft.GetHelp",
    "Microsoft.windowscommunicationsapps",
    "Microsoft.People",
    "Microsoft.Skype",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone"
)

# Get provisioned apps
$AppAList = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName

# Loop through the list of appx packages
foreach ($App in $AppList) {
    Write-host "Processing appx package: $($App)"

    # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
    if (($App -in $AppsToRemove)) {
        # Gather package names
        $AppPackageFullName = Get-AppxPackage -Name $App | Select-Object -ExpandProperty PackageFullName -First 1
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Select-Object -ExpandProperty PackageName -First 1

        # Attempt to remove AppxPackage
        if ($AppPackageFullName -ne $null) {
            Write-host "Removing AppxPackage: $($AppPackageFullName)"
            Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop | Out-Null
        }
        else {
            Write-host "Unable to locate AppxPackage for current app: $($App)"
        }

        # Attempt to remove AppxProvisioningPackage
        if ($AppProvisioningPackageName -ne $null) {
            Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop | Out-Null
        } else {
            Write-host "Unable to locate AppxProvisioningPackage for current app: $($App)"
        }
    }
}

