<#

.COPYRIGHT
Licensed under the MIT license.
See LICENSE in the project root for license information.

Version History
0.1    28th July 2022    Initial version
#>

####################################################

####################################################
[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $fileName="export.csv",
    [switch]$ios=$true,
    [switch]$macos=$true
)
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

    
####################################################

####################################################
Function Get-Devices {
    
    [cmdletbinding()]

    param
    (
        [switch]$ios=$false,
        [switch]$macos=$false
    )

    
    $graphApiVersion = "beta"
    If ($ios -eq $true -and $macOS -ne $true) {
        $resource="deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'"
    }
    If ($ios -ne $true -and $macOS -eq $true) {
        $resource="deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    }
    If ($ios -eq $true -and $macOS -eq $true) {
        $resource="deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS' or operatingSystem eq 'macOS'"
    }

    try
    {
        $results=@()
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$($filter)"
        $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        $results+=$result

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
                $results+=$result

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

function CheckAuthToken ($user) {
    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if($TokenExpires -le 1){
        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        $global:authToken = Get-AuthToken -user $user
    }
}

####################################################


if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host
}

# Checking if authToken exists before running authentication
CheckAuthToken $user

#endregion

####################################################




$devices=(Get-Devices -ios:$ios -macos:$macos).value

$InventoryResults=@()
write-output "$($devices.count) returned."
Foreach ($device in $devices) {
    $uri="https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)?`$select=id,hardwareinformation"
    $results2=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    $device | add-member -NotePropertyName ProductName -NotePropertyValue $results2.hardwareInformation.productname
    $InventoryResults+=$device
}

#get on latest check in for duplicates
$UniqueList = $InventoryResults | Group-Object -Property serialnumber | ForEach-Object{$_.Group | Sort-Object -Property lastsyncdatetime -Descending | Select-Object -First 1}

#display summary
$UniqueList | Format-Table serialnumber,productname,lastsyncdatetime

#export to CSV
write-host "Showing $($UniqueList.count) filtered results by serialNumber and lastSyncDateTime. Exporting to $fileName."
$UniqueList | export-csv -NoTypeInformation $fileName
