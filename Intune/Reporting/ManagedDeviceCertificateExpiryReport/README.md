# Managed Device Certificate Expiry Report
This script provides a summary of devices that are about to have expired management certificates. It is important to check that devices have updated their management certificate before they expire of they will no longer be able to connect to Intune.

Intune will attempt to update the management certficate starting at 45 days before expiry.

This report will provide a the number of devices with 45 days until expiry and then export a list of all devices with the following properties:
- ID
- DeviceName
- DeviceType
- IMEI
- UserPrincipalName
- SerialNumber
- LasySyncDateTime
- ManagementCertificateExpirationDate - the management certificate expiry date.
- DaysUntilExpiry - the numnber of days until the management certificate expires.
- Expired - true if management certificate has expired, false if still valid.

## Parameters
- fileName - the path for the report. Default is .\ManagedDeviceCertificateExpiryReport.csv

## Example Output
```
Welcome To Microsoft Graph!
getting devices
14 returned
There are 2 devices that have expired management certificates
There are 5 devices that will expire in less than 45 days
Exported to ManagedDeviceCertificateExpiryReport.csv
```

## Example Report
|Id|DeviceName|DeviceType|Imei|UserPrincipalName|SerialNumber|LastSyncDateTime|ManagementCertificateExpirationDate|DaysUntilExpiry|Expired|
|-|-|-|-|-|-|-|-|-|-|
|fa8cccc-ccccc-4b56-cccc-07a1c920f5da|Scott's iPad|iPad||user@domain.com|00000000000|15/09/2022 22:07|1/08/2023 15:20|316|FALSE|
