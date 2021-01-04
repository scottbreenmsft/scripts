# Set Device Ownership
These are some sample scripts of how you could change the device ownership type of devices in Intune.

## SetOwnerTypeBySerial.ps1
This script sets the owner type to Corporate for all devices listed in a CSV file by serial number.

### CSV File Format
The CSV file should have a single column with the header "SerialNumber".

For example:
| SerialNumber |
|---|
|123456|
