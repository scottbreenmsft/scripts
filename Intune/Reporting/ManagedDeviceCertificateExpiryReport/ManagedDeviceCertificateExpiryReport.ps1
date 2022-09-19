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

#Limit the list of properties to show and add new properties DaysUntilExpiry and Expired
$devices=$devices | Select-Object Id, DeviceName, DeviceType, IMEI, UserPrincipalName, SerialNumber, LastSyncDateTime, ManagementCertificateExpirationDate, @{Name="DaysUntilExpiry";Expression={($_.managementCertificateExpirationDate - (Get-date)).days}}, @{Name="Expired";Expression={If ($_.managementCertificateExpirationDate -lt (Get-date)){$true}else{$false}}}

#Provide Management Certificate status summary
write-host "There are $(($devices | Where-Object {$_.Expired}).count) devices that have expired management certificates" -ForegroundColor red
write-host "There are $(($devices | Where-Object {$_.DaysUntilExpiry -lt 30}).count) devices that will expire in less than 30 days"
write-host "There are $(($devices | Where-Object {$_.DaysUntilExpiry -ge 30 -and $_.DaysUntilExpiry -lt 60}).count) devices that will expire in less than 60 days"

#export the full device list to $fileName
$devices | Export-Csv $fileName -NoTypeInformation
write-host "Exported report with all devices and their expiration date, days until expiry and expiry status to $fileName"
