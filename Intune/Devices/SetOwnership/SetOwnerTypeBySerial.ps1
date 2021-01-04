
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

$IntuneModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable

if (!$IntuneModule){

    write-host "Microsoft.Graph.Intune Powershell module not installed..." -f Red
    write-host "Install by running 'Install-Module Microsoft.Graph.Intune' from an elevated PowerShell prompt" -f Yellow
    write-host "Script can't continue..." -f Red
    write-host
    exit

}

####################################################

if(!(Connect-MSGraph)){

    Connect-MSGraph

}

####################################################

Update-MSGraphEnvironment -SchemaVersion beta -Quiet

####################################################

$CSVPath = "C:\temp\SerialNumbers\serialNumbers.csv"

if(!(Test-Path $CSVPath)){

    Write-Host
    Write-Host "Path to CSV doesn't exist..." -ForegroundColor Red
    Write-Host "Script can't continue..." -ForegroundColor Red
    Write-Host

}

$SerialNumbers = import-csv "$CSVPath"

####################################################

Write-Host

foreach($entry in $SerialNumbers){

    $SerialNumber = $entry.SerialNumber

    $Devices = Get-IntuneManagedDevice -Filter "serialNumber eq '$SerialNumber'"

    if($Devices){

        foreach ($Device in $Devices) {
            
            write-host "------------------------------------------------------------------"
            Write-Host
            write-host "Device Name:"$Device.deviceName -f Green
            Write-Host "Device Id:"$Device.id
            Write-Host "Owner Type:"$Device.ownerType
            Write-Host "Serial Number:"$Device.serialNumber
            write-host "Operating System:"$Device.operatingSystem
            write-host "Device Type:"$Device.deviceType
            write-host "Compliance State:"$Device.complianceState
            write-host "AAD Registered:"$Device.aadRegistered
            write-host "Management Agent:"$Device.managementAgent
            Write-Host

            # Checking if Intune Managed Device OwnerType is personal
            if($Device.ownerType -eq "personal"){

                $OwnerType = "company"

                Write-Host "Setting device ownership to '$OwnerType'..." -ForegroundColor Yellow

                # Uncomment if you want to update ownerType
                # Update-IntuneManagedDevice -managedDeviceId $Device.id -managedDeviceOwnerType company
                Write-Host
                                                        
            }

            else {

                Write-Host "Device already set to Corporate Ownership Type..." -ForegroundColor Green
                Write-Host

            }
        }

    }

    else {

        Write-Host "------------------------------------------------------------------"
        Write-Host
        Write-Host "Can't find Intune Managed Device with serial number '$SerialNumber'..." -ForegroundColor Red
        Write-Host

    }

}
