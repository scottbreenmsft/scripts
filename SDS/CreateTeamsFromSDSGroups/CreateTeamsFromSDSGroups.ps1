﻿

#This is the App Registration client ID for this script that is used to access the Graph API
#   permissions required:
#     - Group.ReadWrite.All
$ApplicationClientID="<update me>"


##############################################
# Temporarily turn on verbose
##############################################
#$VerbosePreference="Continue"


##############################################
# Temporarily turn on verbose
##############################################
#$VerbosePreference="Continue"


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
                    write-host "`tGroup not found, waiting for replication"
                } else {
                    write-host "Response content:`n$responseBody" 
                }

                Write-host "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
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
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Section'"

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

function CheckAuthToken {
    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if($TokenExpires -le 0){
        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        $global:authToken = Get-AuthToken -User $User
    }
}



##############################################
#
#
##############################################


#region Authentication

#get username so we can renew token as needed
if($User -eq $null -or $User -eq ""){
    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
}

# Checking if authToken exists before running authentication
if($global:authToken){
    CheckAuthToken
} else {

    # Authentication doesn't exist, calling Get-AuthToken function
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

#get a list of schools from the list of classes. Prompt the user to select the schools.
$schools=$classesWithoutTeams | group extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId | sort name | select name,@{n="Classes";e={$_.count}} | Out-GridView -title "Select the schools to provision" -PassThru
write-host "$($schools.count) schools selected without teams"
write-host "Actioning: `n$($schools.name -join "`n")"

#create an object to store how long it takes to create each team
$time=@()

#create an object to store failed classes
$failedclasses=@()

#enumerate through each of the selected schools
$schoolCount=0
foreach ($school in $schools) {
    $schoolCount++
    write-host "processing $($school.name)"
    IF ($schools.count -gt 0) {
        Write-Progress -Id 0 -PercentComplete $($schoolCount/$($schools.count) * 100) -Activity "processing $($school.name)" -Status "$schoolCount out of $($schools.count)"
    }

    #get the list of classes for this school
    $classesWithoutTeamsInSchool=@($classesWithoutTeams | where {$_.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId -eq $school.name})
    write-host "$($classesWithoutTeamsInSchool.count) classes in $($school.name) without teams"

    #enumerate through each class that doesn't have a team, check it has an owner and create a Team
    $classCount=0
    foreach ($class in $classesWithoutTeamsInSchool) {
        #check auth token
        CheckAuthToken

        $classCount++
        IF ($classesWithoutTeamsInSchool.count -gt 0) {
            Write-Progress -Id 1 -PercentComplete $($classCount/$($classesWithoutTeamsInSchool.count) * 100) -Activity "processing $($class.displayName)" -Status "$classCount out of $($classesWithoutTeamsInSchool.count)"
        }
        
        #We cannot create Teams for groups without owners, so we'll check the group has an owner first.
        #each group created by SDS will have a service principal owner, so we have to check if there is more than 1 owner.
        IF ((GetGroupOwners $Class.ID).count -lt 2) {
            write-host "no owners for $($Class.displayName) | $($Class.ID). Teams cannot be created for Office 365 groups without owners." -ForegroundColor red

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
                write-host "successfully created team for $($Class.displayName) | $($Class.ID) | $difference seconds"
            } else {
                write-host "failed to create team for $($Class.displayName) | $($Class.ID)"
                $failedclasses+=$class
            }
        }
    }
}

#retry failed classes
$failedclasses2=@()
If ($failedclasses) {
    write-host "attempting to create failed classes"
    foreach ($class in $failedclasses) {
        $result=CreateClassTeamFromGroup $Class.ID
        if ($result) {
                #output result
                write-host "successfully created team for $($Class.displayName) | $($Class.ID) | $difference seconds"
            } else {
                write-host "failed to create team for $($Class.displayName) | $($Class.ID)"
                $failedclasses2+=$class
            }
    }
}



#summarise results
write-host "failed to create $($failedclasses2.count) classes. `n $($failedclasses2.displayname -join "`n")"
write-host "It took an average of $(($time | Measure-Object -Average).Average) seconds to create each Team"
