<#
.COPYRIGHT
    Licensed under the MIT license.
    See LICENSE in the project root for license information.

.SYNOPSIS
    Remove built-in apps (modern apps) from Windows 10.

.DESCRIPTION
    For info, see https://github.com/scottbreenmsft/scripts/edit/master/Intune/Windows/RemoveApps

.EXAMPLE
    .\RemoveWin10Apps.ps1

.NOTES
    FileName:    RemoveApps.ps1
    Author:      Scott Breen

    Version history:
    0.1 - Initial script
    0.2 - updated with new Windows 11 xbox app 
    0.3 - updated with additional Windows 11 23H2 apps

#>

Start-Transcript -Path "$env:temp\RemoveApps.log"

# List of apps to remove
$AppsToRemove = @(
    "Clipchamp.Clipchamp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.GetStarted",
    "Microsoft.MicrosoftJournal",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.People",
    "Microsoft.Skype",
    "Microsoft.windowscommunicationsapps",
    "Microsoft.Windows.DevHome",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

Write-output "Apps to remove:`n$($AppsToRemove -join "`n")"

# Get provisioned apps
$AppList = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName

# Loop through the list of appx packages
foreach ($App in $AppList) {
    Write-output "Processing appx package: $($App)"

    # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
    if (($App -in $AppsToRemove)) {
        # Gather package names
        $AppPackageFullName = Get-AppxPackage -Name $App | Select-Object -ExpandProperty PackageFullName -First 1
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Select-Object -ExpandProperty PackageName -First 1

        # Attempt to remove AppxPackage
        if ($AppPackageFullName -ne $null) {
            Write-output "Removing AppxPackage: $($AppPackageFullName)"
            Remove-AppxPackage -Package $AppPackageFullName -allusers
        }
        else {
            Write-output "Unable to locate AppxPackage for current app: $($App)"
        }

        # Attempt to remove AppxProvisioningPackage
        if ($AppProvisioningPackageName -ne $null) {
            Write-output "Removing AppxProvisionedPackage: $($AppProvisioningPackageName)"
            Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online
        } else {
            Write-output "Unable to locate AppxProvisioningPackage for current app: $($App)"
        }
    }
}

Stop-Transcript
