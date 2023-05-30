<#

.COPYRIGHT
Licensed under the MIT license.
See LICENSE in the project root for license information.

Version History
0.1    Scott Breen    3/12/2019     Initial version
0.2    Scott Breen    10/12/2020    Updated to work with roles that do not have scope tags assigned
0.3    Scott Breen    30/05/2022    Updated to be more efficient
#>

####################################################
Function Get-RoleAssignments(){

    [cmdletbinding()]
    param (
        $id
    )
    
    $graphApiVersion = "Beta"
    If ($testpaging) {
        $page=$testpaging
    } else {
        $page="?$top=25"
    }
    
    If ($id) {
        $resource = "deviceManagement/roleDefinitions/$($id)?`$expand=roleassignments"
    } else {
        $resource = "deviceManagement/roleAssignments/$page"
    }
    
        try {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
            $results=$result.roleAssignments
    
            #page if necessary - https://docs.microsoft.com/en-us/graph/paging
            if ($result."@odata.nextLink") {
                write-verbose "$($results.count) returned. More results are available, will begin paging."
                $noMoreResults=$false
                do {
    
                    #retrieve the next set of results
                    $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
                    $results+=$result.roleAssignments
    
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
            Write-VERBOSE "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    
        }
    
    }
    
    
    Function Get-RoleAssignment(){
    
    [cmdletbinding()]
    param (
        $id
    )
    
    $graphApiVersion = "Beta"
    If ($testpaging) {
        $page=$testpaging
    } else {
        $page="?$top=25"
    }
    
    If ($id) {
        $resource = "deviceManagement/roleAssignments/$id"
    } else {
        $resource = "deviceManagement/roleAssignments/$page"
    }
    
        try {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            return $result
    
        }
    
        catch {
    
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-VERBOSE "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    
        }
    
    }
    
    
    Function get-roleScopeTags(){
    
    [cmdletbinding()]
    param (
        $definition,
        $assignment
    )
    
    $graphApiVersion = "Beta"
    If ($testpaging) {
        $page=$testpaging
    } else {
        $page="?$top=25"
    }
    
    If ($definition) {
        $resource = "deviceManagement/roleAssignments/$($assignment)?`$expand=microsoft.graph.deviceAndAppManagementRoleAssignment/roleScopeTags"
    } else {
        $resource = "deviceManagement/roleScopeTags"
    }
    
        try {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
            $results=$result.roleScopeTags
    
            #page if necessary - https://docs.microsoft.com/en-us/graph/paging
            if ($result."@odata.nextLink") {
                write-verbose "$($results.count) returned. More results are available, will begin paging."
                $noMoreResults=$false
                do {
    
                    #retrieve the next set of results
                    $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get
                    $results+=$result.roleScopeTags
    
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
        Write-verbose "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        
        }
    
    }
    
    
    
    ####################################################
    Function Get-RoleDefinitions(){
    
    [cmdletbinding()]
    
    
    $graphApiVersion = "Beta"
    If ($testpaging) {
        $page=$testpaging
    } else {
        $page="?$top=25"
    }
    $resource = "deviceManagement/roleDefinitions"
    
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
    
    
    
    Function Get-AzureADGroupNameGraph {
        
    [cmdletbinding()]
        param (
            $id
        )
    
        
        $graphApiVersion = "Beta"
        $Resource = "groups/$id"
        
        try
        {
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            return (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
    
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
    
    #ask for user
    $UPN=read-host "user to check"
    #$UPN="cbeane@academy.scottbreen.tech"
    
    #getAzureADGroups
    $groups=Get-UserGroups -id $UPN
    
    #get role definitions
    $roleDefinitions=Get-RoleDefinitions
    
    #get assignments and scopes
    $relevantAssignments=@()
    foreach ($roleDefinition in $roleDefinitions) {
        write-host ""
        write-host "checking $($roleDefinition.displayName)"
        $RoleAssignments=Get-RoleAssignments -id $roleDefinition.id
        
        foreach ($assignment in $RoleAssignments) {
            write-host "`tRole assignment name: $($assignment.displayName)"
            $RoleAssignment=Get-RoleAssignment $assignment.id
            write-host "`tRole assignment admin group IDs: $($RoleAssignment.members)"
            
            foreach ($Member in $RoleAssignment.members) {
                if ($groups -contains $Member) {
                    $groupname=(Get-AzureADGroupNameGraph $member).displayName
                    write-host "`tUser found in Azure AD Group $groupname" -ForegroundColor Green
                    $scopes=get-roleScopeTags -definition $roleDefinition.id -assignment $assignment.id
                    If ($scopes) {
                        foreach ($scope in $scopes) {
                            #write-host $scope.displayName
                            $Object = New-Object PSObject -Property @{
                                Role=$roleDefinition.displayName
                                RoleAssignment=$assignment.displayName
                                ScopeTags=$scope.displayName
                                GroupName=$groupname
                            }
                            $relevantAssignments+=$object
                        }
                    } else {
                        $Object = New-Object PSObject -Property @{
                            Role=$roleDefinition.displayName
                            RoleAssignment=$assignment.displayName
                            ScopeTags=$null
                            GroupName=$groupname
                        }
                        $relevantAssignments+=$object
                    }
                }
            }
        }
    }
    If ($relevantAssignments) {
        $relevantAssignments|ft
    } else {
        write-host "No roles assigned to user"
    }
