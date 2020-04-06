

#This is the App Registration client ID for this script that is used to access then Graph API
#   permissions required:
#     - Group.ReadWrite.All
$ApplicationClientID="d84f9025-2432-4c72-8a40-84ef30fdee2c"


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

    $clientId = $ApplicationClientID
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

##############################################
#
#
##############################################





####################################################
Function CreateClassTeamFromGroup {
	
[cmdletbinding()]

param
(
	[Parameter(Mandatory=$true)]
	[string]$groupId
)
	
	$graphApiVersion = "beta"
	$Resource = "teams"

#create the JSON object for the POST.
    $JSON=@"
{
  "template@odata.bind": "https://graph.microsoft.com/beta/teamsTemplates('educationClass')",
  "group@odata.bind": "https://graph.microsoft.com/beta/groups('$groupId')"
}
"@

    #initial variables for the loop
    $count=0
    $created=$false

    #attempt to create the Team 3 times with a 10 second delay between each attempt.
    do {	
	    try
	    {

            $Count++
		    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            write-verbose "attempting to create team for $groupId"
		    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
            $created=$true
	    }catch
	    {
		
		    $ex = $_.Exception
            If ($ex.Response) {
		        $errorResponse = $ex.Response.GetResponseStream()
		        $reader = New-Object System.IO.StreamReader($errorResponse)
		        $reader.BaseStream.Position = 0
		        $reader.DiscardBufferedData()
		        $responseBody = $reader.ReadToEnd();
		        

                IF ($responseBody -like '*Status code: NotFound.*') {
                    
                } else {
                    write-verbose "Response content:`n$responseBody" 
                }

                #Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            } else {
               #write-error $ex.message
            }
		    
            write-verbose "waiting 10 seconds"
            start-sleep -seconds 10
		
	    }

    } until ($Created -or ($count -ge 3))
	
    #return result
    If ($Created) {
        return $true
    } else {
        return $false
    }

}



####################################################
Function GetGroupOwners {
	
[cmdletbinding()]

param
(
	[Parameter(Mandatory=$true)]
	[string]$groupId
)
	
	$graphApiVersion = "beta"
	$Resource = "groups/$groupId/owners"

	try
	{

        $Count++
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ContentType "application/json").VALUE
	}catch
	{
		
		$ex = $_.Exception
        If ($ex.Response) {
		    $errorResponse = $ex.Response.GetResponseStream()
		    $reader = New-Object System.IO.StreamReader($errorResponse)
		    $reader.BaseStream.Position = 0
		    $reader.DiscardBufferedData()
		    $responseBody = $reader.ReadToEnd();
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        } else {
            write-error $ex.message
        }
		    

	}



}



####################################################
Function GetClassGroups() {
	
	$graphApiVersion = "beta"
	$Resource = "groups"
	
	try
	{
        #create a results object to store the results from multiple pages
        $results=@()

        #create the URI string with the filter
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Section' and extension_fe2174665583431c953114ff7268b7b3_Education_Status eq 'Active'"

        #retrieve the first page of results
		$result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ContentType "application/json"

        #store the results in the results object
        $results=$result.value

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get
                $results+=$result.value

                #check if we need to continue paging
                If (-not $result."@odata.nextLink") {
                    $noMoreResults=$true
                    write-verbose "$($results.count) returned. No more pages."
                } else {
                    write-verbose "$($results.count) returned so far. Retrieving next page."
                }
            } until ($noMoreResults)
        }

        #return the results
        return $results
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


##############################################
#
#
##############################################



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










##############################################
#
#
##############################################





#get the Office 365 groups that were created using SDS and are active classes
$classes=GetClassGroups
write-host "$($classes.count) classes"

#filter out the Office 365 groups that already have teams created
$classesWithoutTeams=$Classes | where {$_.resourceProvisioningOptions -notcontains "Team"}
write-host "$($classesWithoutTeams.count) classes without teams"

#create an object to store how long it takes to create each team
$time=@()

#enumerate through each class that doesn't have a team, check it has an owner and create a Team
foreach ($class in $classesWithoutTeams) {

    #We cannot create Teams for groups without owners, so we'll check the group has an owner first.
    #each group created by SDS will have a service principal owner, so we have to check if there is more than 1 owner.
    IF ((GetGroupOwners $Class.ID).count -lt 2) {
        write-host "no owners for $($Class.ID) - resolve before group creation successful" -ForegroundColor red

    } else {
        #record the time immediately prior to attempting to create the team
        $start=get-date

        #attempt to create the Team
        $result=CreateClassTeamFromGroup $Class.ID

        #record results
        if ($result) {

            #get the time to create information
            $end=get-date
            $difference=($end-$start).seconds
            $time+=$difference

            #output result
            write-host "successfully created team for $($Class.displayName) | $($Class.ID)"
        } else {
            write-host "failed to create team for $($Class.displayName) | $($Class.ID)"
        }
    }
}

#summarise results
write-host "It took an average of $(($time | Measure-Object -Average).Average) seconds to create each Team"
