<#

.COPYRIGHT
Licensed under the MIT license.
See LICENSE in the project root for license information.

.DESCRIPTION
For info, see https://github.com/scottbreenmsft/scripts/tree/master/AzureAD/AdminUnit/Sync-AADAdminUnitMembership

Version History
0.1    20/11/2020    Initial version
0.2    20/11/2020    Script now accepts group names and administrative units as parameters and allows different attributes to be used for matching

#>

####################################################
#Parameters
####################################################
#Azure AD  App Details for Auth
$tenant = "tenant.onmicrosoft.com"
$clientId = "ClientGUID"
$CertificateThumbprint="CertThumbprint"
$CertificateLocation="cert:\currentuser\my\$CertificateThumbprint"

#Add each of the group name templates you want to search for and add users from
#The assumption being that you have groups that comtain a name or email address that are the same across schools but have reference to the school code
$GroupNameTemplates=@()
$GroupNameTemplates+="SchoolTeachersSG_%SchoolCode%"
$GroupNameTemplates+="SchoolStudentsSG_%SchoolCode%"

#the attribute to match against (i.e. mail or displayName)
$groupattribute="mailNickname"

#The admin unit naming template.
#The assumption being that the administrative units have a common prefix or suffix which is unique by school code.
$AdminUnitTemnplate="%SchoolCode%"

#the attribute to match against (i.e. description or displayName)
$AdminUnitAttribute="description"

#school codes to action
$SchoolCodes=@()
$SchoolCodes+="1001"
$SchoolCodes+="1002"

####################################################
function Get-AuthTokenCertificate {

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

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"

    #Load Azure AD Module for Authentication
    $saveVerbosePreference=$VerbosePreference
    $global:VerbosePreference = 'SilentlyContinue'
    $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    $global:VerbosePreference = $saveVerbosePreference
    if ($AadModule -eq $null) {
        write-error "AzureAD Powershell module not installed..."
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
    } else {
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    

    try {

        #https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.authenticationcontext.acquiretokenasync?view=azure-dotnet#Microsoft_IdentityModel_Clients_ActiveDirectory_AuthenticationContext_AcquireTokenAsync_System_String_Microsoft_IdentityModel_Clients_ActiveDirectory_ClientCredential_
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
        $cert=get-item $CertificateLocation
        $clientCertificate = New-Object -TypeName "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate"($clientID, $cert)
        $authResult=$authContext.AcquireTokenAsync($resourceAppIdURI, $clientCertificate).result

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
Function Get-GroupMembers {
	
    [cmdletbinding()]
    param (
        $id
    )

    
    $graphApiVersion = "Beta"
    $Resource = "groups/$id/transitiveMembers"
    #$body='{"securityEnabledOnly": true}'
    
    try
    {
        $results=@()
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $result=(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
        $results+=$result.value.id

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
                $results+=$result.value.id

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

Function Get-AdministrativeUnitUserMembers {
	
    [cmdletbinding()]
    param (
        $id
    )

    
    $graphApiVersion = "Beta"
    $Resource = "directory/administrativeUnits/$id/members"
    #$body='{"securityEnabledOnly": true}'
    
    try
    {
        $results=@()
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $result=(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
        
        #only return user results
        foreach ($resultobject in $result.value) {
            If ($resultobject."@odata.type" -eq "#microsoft.graph.user") {
                $results+=$resultobject.id
            }
        }

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue

                #only return user results
                foreach ($resultobject in $result) {
                    If ($resultobject."@odata.type" -eq "#microsoft.graph.user") {
                        $results+=$resultobject.id
                    }
                }
                
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

Function Get-AdministrativeUnit {
	
    [cmdletbinding()]
    param (
        $filter
    )

    If ($filter) {
        $filter="?`$filter=$filter"
    }
    $graphApiVersion = "v1.0"
    $Resource = "directory/administrativeUnits$filter"
    #$body='{"securityEnabledOnly": true}'
    
    try
    {
        $results=@()
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $result=(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
        $results+=$result.value

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
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
Function Get-Groups {
	
    [cmdletbinding()]
    param (
        $filter
    )

    If ($filter) {
        $filter="?`$filter=$filter"
    }
    $graphApiVersion = "Beta"
    $Resource = "groups$filter"
    #$body='{"securityEnabledOnly": true}'
    
    try
    {
        $results=@()
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $result=(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
        $results+=$result.value.id

        #page if necessary - https://docs.microsoft.com/en-us/graph/paging
        if ($result."@odata.nextLink") {
            write-verbose "$($results.count) returned. More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
                $results+=$result.value.id

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
    
Function Add-UserToAdminUnit {
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$adminunitobjectid,
        [Parameter(Mandatory=$true)]
        [string]$user
    )
        
        $graphApiVersion = 
        
        
        "Beta"
        $Resource = "directory/administrativeUnits/$adminunitobjectid/members/`$ref"
        
        try
        {
    
        $JSON=@"
    {
    "`@odata.id": "https://graph.microsoft.com/$graphApiVersion/directoryObjects/$user"
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


Function Remove-UserFromAdminUnit {
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$adminunitobjectid,
        [Parameter(Mandatory=$true)]
        [string]$user
    )
        
        $graphApiVersion = 
        
        
        "Beta"
        $Resource = "directory/administrativeUnits/$adminunitobjectid/members/$user/`$ref"
        
        try
        {
    
        $JSON=@"
    {
    "`@odata.id": "https://graph.microsoft.com/$graphApiVersion/directoryObjects/$user"
    }
"@
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete -Body $JSON -ContentType "application/json"

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

    if($TokenExpires -le 1){
        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        $global:authToken = Get-AuthTokenCertificate
    }
}
    
####################################################
    
    
CheckAuthToken
write-host "Getting administrative units"
$AdminUnits = Get-AdministrativeUnit


foreach ($schoolcode in $SchoolCodes) {
    # Checking if authToken exists and is still valid before running authentication
    CheckAuthToken

    write-host "`nprocessing school code: $schoolcode"

    #get the ID of the admin unit
    $AdminUnitName=$AdminUnitTemnplate.Replace("%SchoolCode%",$schoolcode)
    $AdminUnitObjectID=($AdminUnits | Where-Object {$_.$AdminUnitAttribute -eq $AdminUnitName}).id
    #Get-AdministrativeUnit -filter "$AdminUnitAttribute eq '$AdminUnitName'"

    If($AdminUnitObjectID){
        write-host "admin unit ID is $AdminUnitObjectID"

        #get the IDs of the members of the admin unit
        $AdminUnitMembers=Get-AdministrativeUnitUserMembers $AdminUnitObjectID
        write-host "$($AdminUnitMembers.count) user in admin unit $AdminUnitObjectID"

        #create search filter
        $Filter=$null
        Foreach ($GroupName in $GroupNameTemplates) {
            $GroupName=$GroupName.replace("%SchoolCode%",$schoolcode)
            If ($filter) {
                $filter="$filter or "
            }
            $Filter="$filter$groupattribute eq '$GroupName'"
        }

        #get the IDs of the groups to sync with the admin unit
        $Groups=@()
        $Groups=Get-Groups -filter $Filter
        write-host "$($Groups.count) groups returned"

        If ($Groups.count -ge 1) {
            
            #Get the members of the groups returned by the filter
            $members=@()
            Foreach ($group in $groups) {
                $GroupMembers=Get-GroupMembers -id $group
                $members+=$GroupMembers

                write-host "$($GroupMembers.count) members found in $group"
            }

            #ensure we're only processing each user once
            $members=$members | Select-Object -Unique
            write-host "$($members.count) unique members in groups"

            #remo   ve members who are no longer in the groups
            foreach ($user in $AdminUnitMembers) {
                If ($members -notcontains $user) {
                    write-host "removing $user from admin unit $adminunitobjectid"
                    Remove-UserFromAdminUnit -AdminUnitObjectID $adminunitobjectid -user $user
                }
            }

            #add new members
            foreach ($user in $members) {
                If ($AdminUnitMembers -notcontains $user) {
                    write-host "adding $user to $adminunitobjectid"
                    Add-UserToAdminUnit -AdminUnitObjectID $adminunitobjectid -user $user
                }
            }
        } else {
            write-host "no groups found for $schoolcode"
        }
    } else {
        write-host "Not admin unit found for $schoolcode"
    }
}

