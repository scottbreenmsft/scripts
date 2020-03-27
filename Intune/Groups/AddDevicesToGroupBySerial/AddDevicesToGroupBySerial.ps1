<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.


Version History
0.1    Scott Breen    27/03/2020     Initial version

#>



$CSVFileLocation=C:\temp\devices.csv
$AADGroupName="serialnumbergroup"

##################
#CSV file format
#
#The CSV file should have only one column with the heading serialNumber
#
##################


####################################################
 
function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }

# Getting path to ActiveDirectory Assemblies
# If the module count is greater than 1 find the latest version

    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found
            if($AadModule.count -gt 1){
            $aadModule = $AadModule | select -Unique
            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"
 
    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        # If the accesstoken is valid then create the authentication header

        if($authResult.AccessToken){

        # Creating header for Authorization token

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}



Function Get-AADDevice(){

    <#
    .SYNOPSIS
    This function is used to get an AAD Device from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets an AAD Device registered with AAD
    .EXAMPLE
    Get-AADDevice -DeviceID $DeviceID
    Returns an AAD Device from Azure AD
    .NOTES
    NAME: Get-AADDevice
    #>

    [cmdletbinding()]

    param
    (
        $DeviceID
    )

    # Defining Variables
    $graphApiVersion = "v1.0"
    $Resource = "devices"
    
    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=deviceId eq '$DeviceID'"
    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value 

    }

    catch {

        $ex = $_.Exception
        If ($ex.Response) {
		    $errorResponse = $ex.Response.GetResponseStream()
		    $reader = New-Object System.IO.StreamReader($errorResponse)
		    $reader.BaseStream.Position = 0
		    $reader.DiscardBufferedData()
		    $responseBody = $reader.ReadToEnd();
		    write-verbose "Response content:`n$responseBody" 
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        } else {
            write-error $ex.message
        }
		break

    }

}







Function Add-DeviceMember {
	
[cmdletbinding()]

param
(
	[Parameter(Mandatory=$true)]
	[string]$GroupId,
    [Parameter(Mandatory=$true)]
	[string]$DeviceID
)
	
	$graphApiVersion = "Beta"
	$Resource = "groups/$groupid/members/`$ref"
	
	try
	{

    $JSON=@"
{
"`@odata.id": "https://graph.microsoft.com/$graphApiVersion/directoryObjects/$deviceid"
}
"@

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

	}
	
	catch
	{
		
		$ex = $_.Exception
        If ($ex.Response) {
		    $errorResponse = $ex.Response.GetResponseStream()
		    $reader = New-Object System.IO.StreamReader($errorResponse)
		    $reader.BaseStream.Position = 0
		    $reader.DiscardBufferedData()
		    $responseBody = $reader.ReadToEnd();

            If ($responseBody -like "*One or more added object references already exist for the following modified properties: 'members'*") {
                #no error, object already a member
            } else {
		        write-verbose "Response content:`n$responseBody" 
                Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            }
        } else {
            write-error $ex.message
        }
		
	}
	
}


Function Get-DeviceBySerial {
	
[cmdletbinding()]
param (
    $serialNumber
)

	$graphApiVersion = "beta"
	$Resource = "deviceManagement/managedDevices"

    $filter ="?`$filter=serialNumber eq '$serialNumber'"

	
	try
	{
        
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$filter"
        $uri
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

	}
	
	catch
	{
		
		$ex = $_.Exception
        If ($ex.Response) {
		    $errorResponse = $ex.Response.GetResponseStream()
		    $reader = New-Object System.IO.StreamReader($errorResponse)
		    $reader.BaseStream.Position = 0
		    $reader.DiscardBufferedData()
		    $responseBody = $reader.ReadToEnd();
		    write-verbose "Response content:`n$responseBody" 
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        } else {
            write-error $ex.message
        }
		break
		
	}
	
}


####################################################
Function Get-Group {
	
[cmdletbinding()]
    param (
        $name
    )

	
	$graphApiVersion = "Beta"
	$Resource = "groups"
    $filter ="?`$filter=displayName eq '$name'"
	
	try
	{

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$filter"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value.id

	}
	
	catch
	{
		
		$ex = $_.Exception
        If ($ex.Response) {
		    $errorResponse = $ex.Response.GetResponseStream()
		    $reader = New-Object System.IO.StreamReader($errorResponse)
		    $reader.BaseStream.Position = 0
		    $reader.DiscardBufferedData()
		    $responseBody = $reader.ReadToEnd();
		    write-verbose "Response content:`n$responseBody" 
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        } else {
            write-error $ex.message
        }
		break
		
	}
	
}



















#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion





$deviceNotFound=@()
$AADdeviceNotFound=@()

$devices=import-csv $CSVFileLocation
$AzureADGroupID = Get-Group -name $AADGroupName
foreach ($device in $devices) {
    $managedDevices=(Get-DeviceBySerial -serialNumber $device.serialNumber).value
    If ($managedDevices) {
        foreach($managedDevice in $managedDevices) {
            $ObjectID=(Get-AADDevice $managedDevice.azureADDeviceId).id
            If ($ObjectID) {
                Add-DeviceMember -groupid $AzureADGroupID -deviceid $ObjectID
            } else {
                $AADdeviceNotFound+=$device
            }
        }
    } else {
        $deviceNotFound+=$device
    }
}


write-host "The following devices were not found in Intune: `n$($deviceNotFound.serialNumber -join "`n")"
write-host "The following devices were not found in Azure AD:`n$($AADdeviceNotFound.serialNumber -join "`n")"
