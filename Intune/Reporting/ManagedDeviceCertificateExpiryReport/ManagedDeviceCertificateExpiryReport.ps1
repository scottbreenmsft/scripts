#requires -modules Microsoft.Graph.DeviceManagement

#allow a custom report export location
param (
    $fileName="ManagedDeviceCertificateExpiryReport.csv"
)

#connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

#We need the beta profile because ManagementCertificateExpirationDate is not available in v1.0 (on 19th September 2022)
Select-MgProfile -Name "beta"

#Get all devices from the tenant using graph
write-host "getting devices"
$devices=Get-MgDeviceManagementManagedDevice -All
write-host "$($devices.count) total devices returned"

#Limit the list of properties to show and add new properties DaysUntilExpiry, Expired and NewerDeviceRecord
$devices=$devices | Select-Object Id, DeviceName, DeviceType, IMEI, `
    UserPrincipalName, SerialNumber, LastSyncDateTime, ManagementCertificateExpirationDate, `
    @{Name="DaysUntilExpiry";Expression={($_.managementCertificateExpirationDate - (Get-date)).days}}, `
    @{Name="Expired";Expression={If ($_.managementCertificateExpirationDate -lt (Get-date)){$true}else{$false}}}, `
    @{Name="NewerDeviceRecord";Expression={
        $result=$false
        foreach($device in $devices) {
                If ($_.SerialNumber -eq $device.SerialNumber -and $_.ID -ne $device.ID -and $device.LastSyncDateTime -gt $_.LastSyncDateTime) {
                    $result=$true
                    break
                }
            }
            $result
        }
    }

#Provide Management Certificate status summary
write-host " - There are $(@($devices | Where-Object {$_.NewerDeviceRecord}).count) devices with newer records which have been filtered out of the counts below (matched by serial number). They have NewerDeviceRecord set to true in the exported report."
write-host " - There are $(@($devices | Where-Object {$_.Expired -and -not $_.NewerDeviceRecord}).count) devices that have expired management certificates" -ForegroundColor red
write-host " - There are $(@($devices | Where-Object {$_.DaysUntilExpiry -lt 120 -and -not $_.NewerDeviceRecord}).count) devices that will expire in less than 120 days"

#export the full device list to $fileName
$devices | Export-Csv $fileName -NoTypeInformation
write-host "Exported report with all devices and their expiration date, days until expiry and expiry status to $fileName"
