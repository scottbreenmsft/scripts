This script adds devices to the specified Azure AD group by reading matching the serial numbers from a CSV file to the device record in Intune.

## Parameters
The following properties at the start of the script must be set:

* $CSVFileLocation - the location of the CSV where the serial numbers are stored.
* $AADGroupName - the name of the Azure AD group to add the devices to.

## NOTE
There could be more than one object in Intune for each serial number if devices have been enrolled more than once. If the script can find the corresponding object for each of these devices it will all of them to the Azure AD group.

## CSV file format
The CSV file should have only one column with the heading serialNumber.
