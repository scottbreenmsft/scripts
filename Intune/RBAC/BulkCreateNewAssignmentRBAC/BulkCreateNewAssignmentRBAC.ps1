########################
#https://github.com/scottbreenmsft/scripts/tree/master/Intune/RBAC/BulkCreateNewAssignmentRBAC
########################

param (

    $csvpath=(read-host "Enter CSV path")

)

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


Function get-roleScopeTags(){

[cmdletbinding()]
param (
    $assignment
)

$graphApiVersion = "Beta"
If ($testpaging) {
    $page=$testpaging
} else {
    $page="?$top=25"
}

If ($assignment) {
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
####################################################

Function Assign-RBACRole(){

<#
.SYNOPSIS
This function is used to set an assignment for an RBAC Role using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets and assignment for an RBAC Role
.EXAMPLE
Assign-RBACRole -Id $IntuneRoleID -DisplayName "Assignment" -MemberGroupId $MemberGroupId -TargetGroupId $TargetGroupId
Creates and Assigns and Intune Role assignment to an Intune Role in Intune
.NOTES
NAME: Assign-RBACRole
#>

[cmdletbinding()]

param
(
    $Id,
    $DisplayName,
    $MemberGroupId,
    $TargetGroupId,
    $ScopeTag
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleAssignments"
    
    try {

        if(!$Id){

        write-host "No Policy Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$DisplayName){

        write-host "No Display Name specified, specify a Display Name" -f Red
        break

        }

        if(!$MemberGroupId){

        write-host "No Member Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

        if(!$TargetGroupId){

        write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }


$JSON = @"
    {
    "id":"",
    "description":"",
    "displayName":"$DisplayName",
    "members":["$MemberGroupId"],
    "scopeMembers":["$TargetGroupId"],
    "roleDefinition@odata.bind":"https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$ID')",
    "roleScopeTags@odata.bind": ["https://graph.microsoft.com/beta/deviceManagement/roleScopeTags('$scopetag')"]
    }
"@

    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
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

Function Create-ScopeTag(){

<#
.SYNOPSIS
This function is used to set an assignment for an RBAC Role using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets and assignment for an RBAC Role
.EXAMPLE
Assign-RBACRole -Id $IntuneRoleID -DisplayName "Assignment" -MemberGroupId $MemberGroupId -TargetGroupId $TargetGroupId
Creates and Assigns and Intune Role assignment to an Intune Role in Intune
.NOTES
NAME: Assign-RBACRole
#>

[cmdletbinding()]

param
(
    $name,
    $description
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleScopeTags"
    
    try {

  
$JSON = @"
    {
    "@odata.type":"#microsoft.graph.roleScopeTag",
    "description":"$description",
    "displayName":"$Name",
    "isBuiltIn": true
    }
"@

    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
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

Function Get-AzureADGroupIDGraph {
	
[cmdletbinding()]
    param (
        $name
    )

	
	$graphApiVersion = "Beta"
	$Resource = "groups?`$filter=displayname eq '$name'"
	
	try
	{

		$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
		return (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value.id

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



#import the CSV
$NewRoleAssignments=import-csv $csvpath


foreach ($NewRoleAssignment in $NewRoleAssignments) {
    $RBACRoles=Get-RBACScopeTag
    $ScopeTag=$RbacRoles | where {$_.displayname -eq $NewRoleAssignment.'Scope Tag'}
    If (-not $ScopeTag) {
        #create scope tag
        write-host "Creating scope tag $($NewRoleAssignment.'Scope Tag')"
        $ScopeTag=Create-ScopeTag -name $NewRoleAssignment.'Scope Tag' -description $NewRoleAssignment.'Scope Tag Description'
    } else {
        write-host "using existing scope tag $scopetag"
    }

    #check that the role exists
    $roleDefinition=Get-RoleDefinitions | where {$_.displayName -eq $NewRoleAssignment.Role}


    IF ($roleDefinition) {

        #get the role assignments for the role definition
        $RoleAssignments=Get-RoleAssignments -id $roleDefinition.id
               
        #check assignment doesnt already exist by name
        IF (-not ($RoleAssignments | where {$_.displayname -eq $NewRoleAssignment.'Assignment Name'})) {
            
            #get the group IDs
            $MemberGroupID=Get-AzureADGroupIDGraph $NewRoleAssignment.'Admin Group'
            IF (-not $MemberGroupID) {
                write-host "Cannot find group for $($NewRoleAssignment.'Admin Group')"
            }
            $TargetGroupID=Get-AzureADGroupIDGraph $NewRoleAssignment.'Scope Group'
            IF (-not $TargetGroupID) {
                write-host "Cannot find group for $($NewRoleAssignment.'Scope Group')"
            }

            #create the role assignment
            If ($MemberGroupID -and $TargetGroupID) {
                $assignment=Assign-RBACRole -Id $roleDefinition.id -DisplayName $NewRoleAssignment.'Assignment Name' -MemberGroupId $MemberGroupId -TargetGroupId $TargetGroupId -scopetag $scopetag.id
                if ($assignment) {
                    write-host "assignment with ID $($assignment.id) created"
                } else {
                    write-host "assignment not created"
                }
            }
        } else {
            write-host "a role assignment with the name $($NewRoleAssignment.'Assignment Name') already exists"
        }  
    }
    
}





