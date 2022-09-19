param (
    $fileName="ManagedDeviceCertificateExpiryReport.csv"
)
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
Select-MgProfile -Name "beta"
write-host "getting devices"
$devices=Get-MgDeviceManagementManagedDevice -All
write-host "$($devices.count) returned"
$devices=$devices | Select-Object Id, DeviceName, DeviceType, IMEI, UserPrincipalName, SerialNumber, LastSyncDateTime, ManagementCertificateExpirationDate, @{Name="DaysUntilExpiry";Expression={($_.managementCertificateExpirationDate - (Get-date)).days}}, @{Name="Expired";Expression={If ($_.managementCertificateExpirationDate -lt (Get-date)){$true}else{$false}}}
write-host "There are $(($devices | Where-Object {$_.Expired}).count) devices that have expired management certificates" -ForegroundColor red
write-host "There are $(($devices | Where-Object {$_.DaysUntilExpiry -lt 30}).count) devices that will expire in less than 30 days"
write-host "There are $(($devices | Where-Object {$_.DaysUntilExpiry -ge 30 -and $_.DaysUntilExpiry -lt 60}).count) devices that will expire in less than 60 days"
$devices | Export-Csv $fileName -NoTypeInformation
write-host "Exported to $fileName"
