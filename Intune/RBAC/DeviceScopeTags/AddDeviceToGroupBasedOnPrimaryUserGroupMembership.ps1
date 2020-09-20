<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

Version History
0.1    Scott Breen    3/12/2019     Initial version
0.2    Scott Breen    10/12/2019    Fixed some bugs and changed get-groupmembers function to return members of all subgbroups and to only return the IDs of those objects (using transitiveMembers instead of getGroupMembers).
0.3    Scott Breen    10/12/2019    Changes code to be more efficient in only getting group membership when required and filtering the devices enrolled in the last 24 hours by default.
0.4    Scott Breen    13/01/2020    Changed to use app only authentication
0.5    Scott Breen    13/01/2020    Changed output to work with Azure Automation Runbooks
0.6    Scott Breen    15/01/2020    Small changes, adding logging
0.7    Scott Breen    8/05/2020     Added paging to Get-Devices and Get-GroupMembers functions
0.8    Scott Breen    19/06/2020    Updated to re-auth during execution if required with new function - CheckAuthToken
0.9    Scott Breen    18/09/2020    Updated to support primary user - /users - pending
#>

####################################################
$VerbosePreference = 'Continue'

#by default the script will only investigate objects enrolled within the last 24 hours. Change this to 0 to get all devices. The time is in minutes.
#1440 is 24 hours
$filterByEnrolledWithinMinutes=0

#Record the list of user group to scope tag group mapping here
$UserGroupRoleGroupMapping=@()
$hash = @{                         
        UserGroupID            = "66cc746f-1219-4afb-83e1-2fcf96ea4df2" #10001 - Breen Academy North
        ScopeTagGroupID    = "af5fa98e-2b94-4cd8-9d3f-ec364882fba5"
        }                                              
$UserGroupRoleGroupMapping+=(New-Object PSObject -Property $hash)
$hash = @{                       
        UserGroupID             = "0b59cddd-d56c-4857-98d8-f1bb066a947e" #10002 - Breen Academy South
        ScopeTagGroupID    = "23cf75a8-1ba8-4602-bc4a-cdd2d4e39085"
        }                                              
$UserGroupRoleGroupMapping+=(New-Object PSObject -Property $hash)

#create the property to keep a cached copy of user group membership while the script runs
$cachedUserGroupMemberships=@()

#set to true to filter the devices retrieved to personal devices
$personalOnly=$false

#Azure AD  App Details for Auth
$tenant = "breenacademy.onmicrosoft.com"
$clientId = "851cd1f9-469d-47ba-bfde-eab80639f08f"
$clientSecret = "o6UQ3_uA?5VV_sh:7zBwMppixQiFG8V0"


function Get-AuthTokenClientSecret {

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

	$AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {
		Write-output "AzureAD PowerShell module not found, looking for AzureADPreview"
		$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
	}

    if ($AadModule -eq $null) {
		Write-output "AzureAD PowerShell module not found"
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

	}

	else {

		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

	}


    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"

	try {

        #https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.authenticationcontext.acquiretokenasync?view=azure-dotnet#Microsoft_IdentityModel_Clients_ActiveDirectory_AuthenticationContext_AcquireTokenAsync_System_String_Microsoft_IdentityModel_Clients_ActiveDirectory_ClientCredential_
	    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
        $clientCredential = New-Object -TypeName "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential"($clientID, $clientSecret)
        $authResult=$authContext.AcquireTokenAsync($resourceAppIdURI, $clientCredential).result

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
		    write-error "Authorization Access Token is null, please re-run authentication..."
		    break

		}

	}

	catch {

	    write-output $_.Exception.Message 
	    write-output $_.Exception.ItemName 
	    break

	}

}


####################################################

	
####################################################
Function Get-UserGroups {
	
[cmdletbinding()]
    param (
        $id
    )

	
	$graphApiVersion = "Beta"
	$Resource = "users/$id/getMemberGroups"
    $body='{"securityEnabledOnly": true}'
	
	try
	{

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $body).value

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
Function Get-GroupMembers {
	
[cmdletbinding()]
    param (
        $id
    )

	
	$graphApiVersion = "Beta"
	$Resource = "groups/$id/transitiveMembers"
    $body='{"securityEnabledOnly": true}'
	
	try
	{

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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
Function Get-User {
	
[cmdletbinding()]
    param (
        $id
    )

	
	$graphApiVersion = "Beta"
	$Resource = "users/$id"
	
	try
	{

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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



Function Get-Devices {
	
[cmdletbinding()]

param
(
    $filterByEnrolledWithinMinutes
)

#https://docs.microsoft.com/en-us/graph/query-parameters

	
	$graphApiVersion = "beta"
	$Resource = "deviceManagement/managedDevices"

    If ($filterByEnrolledWithinMinutes) {
        $minutesago = "{0:s}" -f (get-date).addminutes(0-$filterByEnrolledWithinMinutes) + "Z"
        $filter = "?`$filter=enrolledDateTime ge $minutesAgo"

        If ($personalOnly) {
            $filter ="$filter and managedDeviceOwnerType eq 'Personal'"
        }
    } else {
        If ($personalOnly) {
            $filter ="?`$filter=managedDeviceOwnerType eq 'Personal'"
        } else {
            $filter = ""
        }
    }
	
	try
	{
        
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$filter"
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

Function Get-DeviceUsers {
	
[cmdletbinding()]

param
(
    $deviceID
)

#https://docs.microsoft.com/en-us/graph/query-parameters

	
	$graphApiVersion = "beta"
	$Resource = "deviceManagement/managedDevices('$deviceID')/users"



	
	try
	{
        
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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

####################################################

####################################################




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
		    write-verbose "Response content:`n$responseBody" 
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        } else {
            write-error $ex.message
        }
		break
		
	}
	
}

####################################################



# Checking if authToken exists before running authentication
if($global:authToken){

	# Setting DateTime to Universal time to work in all timezones
	$DateTime = (Get-Date).ToUniversalTime()

	# If the authToken exists checking when it expires
	$TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

		if($TokenExpires -le 0){
		    write-verbose "Authentication Token expired $TokenExpires minutes ago"
		    $global:authToken = Get-AuthTokenClientSecret
		}
}

# Authentication doesn't exist, calling Get-AuthToken function

else {
    # Getting the authorization token
    write-output "Authenticating..."
    $global:authToken = Get-AuthTokenClientSecret
}

#endregion

####################################################



IF ($filterByEnrolledWithinMinutes -ne 0) {
    write-output "getting devices recorded as enrolled within the last $filterByEnrolledWithinMinutes minutes"
    $devices=(Get-Devices -filterbyenrolledwithinminutes $filterByEnrolledWithinMinutes).value
} else {
    write-output "getting all devices"
    $devices=(Get-Devices).value
}



foreach ($device in $devices) {
    #get the current primary user of the device
    $PrimaryUser=Get-DeviceUsers $device.id

    #devices without a corresponding Azure AD Device ID cause script problems and should be excluded
    If ($PrimaryUser -and $device.azureADDeviceId -ne "00000000-0000-0000-0000-000000000000") {
        write-output "Processing device: $($device.devicename). Serial: $($device.serialnumber). AADDeviceID= $($device.azureADDeviceId). UserID: $($PrimaryUser)"

        #lets to make sure our auth token is still valid
        CheckAuthToken

        $userGroupMemership=$null

        #check if we have the user group membership in our user group cache
        If ($cachedUserGroupMemberships.UserID -contains $PrimaryUser) {
            foreach ($cachedGroup in $cachedUserGroupMemberships) {
                IF ($cachedGroup.userid -eq $PrimaryUser) {
                    write-verbose "`tusing user group membership cache for user $($PrimaryUser)"
                    $userGroupMemership=$cachedGroup.Groups
                }
            }
        } else {
            write-verbose "`tretreiving groups for user $($PrimaryUser)"
            #keep a cache of the user group membership to reduce graph queries
            $userGroupMemership=Get-UserGroups -id $PrimaryUser
            $hash = @{            
                UserID          = $PrimaryUser                
                Groups            = $userGroupMemership
                }                                              
            $cachedUserGroupMemberships+=(New-Object PSObject -Property $hash)
        }

        #iterate through the users groups and see if they match any of our groups we're using for scope tag mapping
        foreach ($userGroup in $userGroupMemership) {
            If ($UserGroupRoleGroupMapping.UserGroupID -contains $userGroup) {
                write-verbose "`t$userGroup found in mapping, looking for device group"
                
                #assign scope tag group
                foreach ($deviceGroup in $UserGroupRoleGroupMapping) {
                    If ($deviceGroup.UserGroupID -eq $userGroup) {

                        write-verbose "`tuser $PrimaryUser is in a group that matches a scope tag assignment. Group ID is $userGroup."

                        #get group members if needed and cache
                        if (-not $deviceGroup.ScopeTagGroupMembers) {
                            write-verbose "`tgetting groupmembers for $($devicegroup.ScopeTagGroupID)"
                            $deviceGroup | add-member -MemberType NoteProperty -Name ScopeTagGroupMembers -Value (get-groupmembers $deviceGroup.ScopeTagGroupID) -Force
                        }
                        
                        #get the id of the device from Azure AD - we need this to add it to the group
                        write-verbose "`tgetting device from Azure AD with device ID $($device.azureADDeviceId)"
                        $deviceID=(get-aaddevice $device.azureADDeviceId).id

                        #if the device isnt already a member of the group, add it now.
                        IF ($deviceID) {
                            If ($deviceGroup.ScopeTagGroupMembers -notcontains $deviceID) {
                                write-output "`tadding device $deviceID to device scope tag group $($deviceGroup.ScopeTagGroupID)"
                                $result=Add-DeviceMember -GroupId $deviceGroup.ScopeTagGroupID -DeviceID $deviceID
                            } else {
                                write-verbose "`tdevice $deviceID already a member of $($deviceGroup.ScopeTagGroupID)"
                            }
                        } else {
                            write-verbose "`t$($device.azureADDeviceId) Azure AD device not found"
                        }
                    }
                }
                
            }
        }

    }
}


