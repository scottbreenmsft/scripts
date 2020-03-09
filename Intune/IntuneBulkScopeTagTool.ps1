
<#
 
.COPYRIGHT
Licensed under the MIT license.
See LICENSE in the project root for license information.


Version History
0.1    Scott Breen    15/01/2020     Initial version

#>

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
 

####################################################
Function Get-DEPTokens(){

[cmdletbinding()]

param
(
    $name,
    $id
)

$graphApiVersion = "Beta"
If ($testpaging) {
    $page=$testpaging
} else {
    $page="?$top=25"
}
$resource = "deviceManagement/depOnboardingSettings/$page"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
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

        return $results

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Update-DEPToken(){

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $ScopeTags
)

    $graphApiVersion = "beta"
    $Resource = "deviceManagement/depOnboardingSettings/$id"

    try {
     
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "#microsoft.graph.depOnboardingSetting",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "#microsoft.graph.depOnboardingSetting"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"
        Start-Sleep -Milliseconds 100

    }

    catch {

        Write-Host
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        break

    }

}



####################################################
Function Get-VPPTokens(){

[cmdletbinding()]

param
(
    $name,
    $id
)

$graphApiVersion = "Beta"
If ($testpaging) {
    $page=$testpaging
} else {
    $page="?$top=25"
}
$resource = "deviceAppManagement/vppTokens/$page"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
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

        return $results

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Update-VPPToken(){

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $ScopeTags
)

    $graphApiVersion = "beta"
    $Resource = "deviceAppManagement/vppTokens/$id"

    try {
     
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "#microsoft.graph.vppToken",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "#microsoft.graph.vppToken"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"
        Start-Sleep -Milliseconds 100

    }

    catch {

        Write-Host
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        break

    }

}



####################################################
Function Get-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to get device configuration policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device configuration policies
.EXAMPLE
Get-DeviceConfigurationPolicy
Returns any device configuration policies configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    $name,
    $id
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)$testpaging"
        $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        $policies=$result.value

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($policies.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get
                $policies+=$result.value

                #check if we need to continue paging
                If (-not $result."@odata.nextLink") {
                    $noMoreResults=$true
                    write-verbose "$($policies.count) returned. No more pages."
                } else {
                    write-verbose "$($policies.count) returned so far. Retrieving next page."
                }
            } until ($noMoreResults)
        }

        return $policies

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}


####################################################

Function Update-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to update a device configuration policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and updates a device configuration policy
.EXAMPLE
Update-DeviceConfigurationPolicy -id $Policy.id -Type $Type -ScopeTags "1"
Updates an device configuration policy in Intune
.NOTES
NAME: Update-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $Type,
    [Parameter(Mandatory=$true)]
    $ScopeTags
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/deviceConfigurations/$id"

    try {
     
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "$Type",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "$Type"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        Start-Sleep -Milliseconds 100

    }

    catch {

    Write-Host
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-RBACScopeTag(){

<#
.SYNOPSIS
This function is used to get scope tags using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets scope tags
.EXAMPLE
Get-RBACScopeTag -DisplayName "Test"
Gets a scope tag with display Name 'Test'
.NOTES
NAME: Get-RBACScopeTag
#>

[cmdletbinding()]
    
param
(
    [Parameter(Mandatory=$false)]
    $DisplayName
)

# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/roleScopeTags"

    try {

        if($DisplayName){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=displayName eq '$DisplayName'"
            $Result = (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).Value

        }

        else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            $Result = (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).Value

        }

    return $Result

    }

    catch {
    
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    throw
    }

}

####################################################

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



# get scope tags
write-host "prompting to select scope tag to ADD"
$SelectedScopeTag = Get-RBACScopeTag | Out-GridView -PassThru -title "Select the scope tag to apply (close window for none)"  | select -first 1
If ($SelectedScopeTag) {
    write-host "selected scope tag to add $($SelectedScopeTag.id) - $($SelectedScopeTag.displayName)."
} else {
    write-host "no scope tags to add or more than 1 selected. tool only supports one at at time."
    $SelectedScopeTag=$null
}

write-host "prompting to select scope tag to REMOVE"
$SelectedScopeTagtoRemove = Get-RBACScopeTag | Out-GridView -PassThru -title "Select the scope tag to remove (close window for none)" | select -first 1
If ($SelectedScopeTagtoRemove) {
    write-host "selected scope tag for removal $($SelectedScopeTagtoRemove.id) - $($SelectedScopeTagtoRemove.displayName)."
} else {
    write-host "no scope tags to remove."
    $SelectedScopeTagtoRemove=$null
}

# get device configuration profiles
$DeviceConfigPolicies=Get-DeviceConfigurationPolicy
write-host "prompting to select policies"
$selectedPolicies = $DeviceConfigPolicies | select displayname,id,rolescopetagids,"@odata.type" | Out-GridView -PassThru -Title "Select the policies to apply the scope tag to"
write-host "$($selectedPolicies.count) policies to apply scope tag to."

# DEP token - https://docs.microsoft.com/en-us/graph/api/resources/intune-enrollment-deponboardingsetting?view=graph-rest-beta
# https://docs.microsoft.com/en-us/graph/api/intune-enrollment-deponboardingsetting-update?view=graph-rest-beta
$DEPTokens=Get-DEPTokens
write-host "prompting to select DEP tokens"
$SelectedDEPTokens=$DEPTokens | select roleScopeTagIDs,tokenName,id,AppleIdentifier | Out-GridView -PassThru -title "Select the DEP tokens to apply the scope tag to"
write-host "$($SelectedDEPTokens.count) DEP tokens to apply scope tag to."

# VPP token
$DEPTokens=Get-VPPTokens
write-host "prompting to select VPP tokens"
$SelectedVPPTokens=$DEPTokens | select roleScopeTagIDs,displayname,locationname,id,AppleId | Out-GridView -PassThru -title "Select the VPP tokens to apply the scope tag to"
write-host "$($SelectedVPPTokens.count) VPP tokens to apply scope tag to."

# scope tag assignment group copy
# just create a top level group and add all sub groups? to save on having to add multiple groups to the scope tag?

write-host "selected scope tag $($SelectedScopeTag.id) - $($SelectedScopeTag.displayName)."
write-host "$($selectedPolicies.count) policies to apply scope tag to."
write-host "$($SelectedDEPTokens.count) DEP tokens to apply scope tag to."
write-host "$($SelectedVPPTokens.count) VPP tokens to apply scope tag to."


$continue=read-host "Continue? y for yes"


#Update-DEPToken id, roleScopeTagIDs
If ($continue-eq "y") {
    foreach ($DEPToken in $SelectedDEPTokens) {
        $newScope=$DEPToken.rolescopetagIDs

        #process additions
        If ($SelectedScopeTag -and (-not ($DEPToken.rolescopetagIDs -contains $SelectedScopeTag.id))) {
            write-host "adding $($SelectedScopeTag.id) to $($DEPToken.rolescopetagIDs -join ";")"
            $newScope=@($newScope) + @("$($SelectedScopeTag.id)")

            write-host "DEP: applying new scope $newScope to $($DEPToken.tokenName)"
            Update-DEPToken -id $DEPToken.id -ScopeTags $newScope
        }

        #process removals
        IF ($SelectedScopeTagToRemove -and (($newScope -contains $SelectedScopeTagToRemove.id))) {
            write-host "Removing $($SelectedScopeTagToRemove.id) from $($DEPToken.rolescopetagIDs -join ";")"
            $newScopeRemoved=@()
            foreach ($scope in @($newScope)) {
                If (-not ($scope -eq $SelectedScopeTagToRemove.id)) {
                    $newScopeRemoved+=$scope
                }
            }
            $newScope=$newScopeRemoved
            write-host "DEP: applying new scope $newScope to $($DEPToken.tokenName)"
            Update-DEPToken -id $DEPToken.id -ScopeTags $newScope
        }
        
    }
}


#Update-VPPToken id, roleScopeTagIDs
If ($continue-eq "y") {
    foreach ($VPPToken in $SelectedVPPTokens) {
        $newScope=$VPPToken.rolescopetagIDs

        #process additions
        If ($SelectedScopeTag -and (-not ($VPPToken.rolescopetagIDs -contains $SelectedScopeTag.id))) {
            write-host "adding $($SelectedScopeTag.id) to $($VPPToken.rolescopetagIDs -join ";")"
            $newScope=@($newScope) + @("$($SelectedScopeTag.id)")

            write-host "VPP: applying new scope $newScope to $($VPPToken.displayName)"
            Update-VPPToken -id $VPPToken.id -ScopeTags $newScope
        }

        #process removals
        IF ($SelectedScopeTagToRemove -and (($newScope -contains $SelectedScopeTagToRemove.id))) {
            write-host "Removing $($SelectedScopeTagToRemove.id) from $($VPPToken.rolescopetagIDs -join ";")"
            $newScopeRemoved=@()
            foreach ($scope in @($newScope)) {
                If (-not ($scope -eq $SelectedScopeTagToRemove.id)) {
                    $newScopeRemoved+=$scope
                }
            }
            $newScope=$newScopeRemoved

            write-host "VPP: applying new scope $newScope to $($VPPToken.displayName)"
            Update-VPPToken -id $VPPToken.id -ScopeTags $newScope
        }

        
    }
}

#DeviceConfig
If ($continue-eq "y") {
    foreach ($DeviceConfig in $selectedPolicies) {
        $newScope=$DeviceConfig.rolescopetagIDs

        #process additions
        If ($SelectedScopeTag -and (-not ($DeviceConfig.rolescopetagIDs -contains $SelectedScopeTag.id))) {
            write-host "adding $($SelectedScopeTag.id) to $($DeviceConfig.rolescopetagIDs -join ";")"
            $newScope=@($newScope) + @("$($SelectedScopeTag.id)")

            write-host "Configuration Profile: applying new scope $newScope to $($DeviceConfig.displayName)"
            Update-DeviceConfigurationPolicy -id $DeviceConfig.id -ScopeTags $newScope -Type $DeviceConfig."@odata.type"
        }

        #process removals
        IF ($SelectedScopeTagToRemove -and (($newScope -contains $SelectedScopeTagToRemove.id))) {
            write-host "Removing $($SelectedScopeTagToRemove.id) from $($DeviceConfig.rolescopetagIDs -join ";")"
            $newScopeRemoved=@()
            foreach ($scope in @($newScope)) {
                If (-not ($scope -eq $SelectedScopeTagToRemove.id)) {
                    $newScopeRemoved+=$scope
                }
            }
            $newScope=$newScopeRemoved

            write-host "Configuration Profile: applying new scope $newScope to $($DeviceConfig.displayName)"
            Update-DeviceConfigurationPolicy -id $DeviceConfig.id -ScopeTags $newScope -Type $DeviceConfig."@odata.type"
        }
        
    }
}
