
$profilesenum=@{
"AndroidCustom"=1;
"AndroidEmailProfile"=2;
"AndroidDeviceOwnerGeneral"=3;
"AndroidDeviceOwnerDerivedCredentialAppAuthenticationConfiguration"=4;
"AndroidDeviceOwnerImportedPFX"=5;
"AndroidDeviceOwnerPKCS"=6;
"AndroidDeviceOwnerSCEP"=7;
"AndroidDeviceOwnerTrustedCertificate"=8;
"AndroidDeviceOwnerVpn"=9;
"AndroidDeviceOwnerWiFi"=10;
"AndroidForWorkCustom"=11;
"AndroidForWorkEmailProfile"=12;
"AndroidForWorkVpn"=13;
"AndroidForWorkGeneral"=14;
"AndroidForWorkImportedPFX"=15;
"AndroidForWorkOemConfig"=16;
"AndroidForWorkPKCS"=17;
"AndroidForWorkSCEP"=18;
"AndroidForWorkTrustedCertificate"=19;
"AndroidForWorkWiFi"=20;
"AndroidGeneral"=21;
"AndroidImportedPFX"=22;
"AndroidPKCS"=23;
"AndroidSCEP"=24;
"AndroidTrustedCertificate"=25;
"AndroidVPN"=26;
"AndroidWiFi"=27;
"AndroidZebraMx"=28;
"AOSPDeviceOwnerDevice"=29;
"ComplianceAndroid"=30;
"ComplianceAndroidForWork"=31;
"ComplianceAndroidDeviceOwner"=32;
"ComplianceAOSPDeviceOwner"=33;
"ComplianceIos"=34;
"ComplianceMac"=35;
"ComplianceWindows10"=36;
"ComplianceWindows10Mobile"=37;
"ComplianceWindows8"=38;
"ComplianceWindowsPhone"=39;
"ComplianceDefaultPolicy"=40;
"IosCustom"=41;
"IosDeviceFeatures"=42;
"IosDerivedCredentialAuthenticationConfiguration"=43;
"IosEducation"=44;
"IosEmailProfile"=45;
"IosGeneralDevice"=46;
"IosImportedPFX"=47;
"IosPKCS"=48;
"IosPresets"=49;
"IosSCEP"=50;
"IosTrustedCertificate"=51;
"IosUpdate"=52;
"IosVPN"=53;
"IosWiFi"=54;
"IosExpeditedCheckin"=55;
"MacOSCustom"=56;
"MacOSCustomApp"=57;
"MacOSDeviceFeatures"=58;
"MacOSEndpointProtection"=59;
"MacOSExtensions"=60;
"MacOSGeneral"=61;
"MacImportedPFX"=62;
"MacSCEP"=63;
"MacOSPKCS"=64;
"MacOSTrustedCertificate"=65;
"MacOSVPN"=66;
"MacOSWiFi"=67;
"MacOSWiredNetwork"=68;
"MacOSSoftwareUpdate"=69;
"Unsupported"=70;
"windowsDefenderAdvancedThreatProtection"=71;
"Windows10AtpStreamlinedOnboarding"=72;
"Windows10Custom"=73;
"windowsUpdateForBusiness"=74;
"Windows10EmailProfile"=75;
"Windows10EndpointProtection"=76;
"Windows10EnterpriseDataProtection"=77;
"Windows10General"=78;
"Windows10Kiosk"=79;
"Windows10PolicyOverride"=80;
"Windows10PKCS"=81;
"Windows10ImportedPFX"=82;
"Windows10SCEP"=83;
"Windows10SecureAssessmentProfile"=84;
"sharedPC"=85;
"Windows10TeamGeneral"=86;
"Windows10TrustedCertificate"=87;
"Windows10VPN"=88;
"Windows10WiFi"=89;
"Windows10NetworkBoundary"=90;
"Windows8General"=91;
"Windows8SCEP"=92;
"Windows8TrustedCertificate"=93;
"Windows8VPN"=94;
"Windows8WiFi"=95;
"EditionUpgrade"=96;
"WindowsIdentityProtection"=97;
"WindowsPhoneCustom"=98;
"WindowsPhoneEmailProfile"=99;
"WindowsPhoneGeneral"=100;
"WindowsPhoneImportedPFX"=101;
"WindowsPhoneSCEP"=102;
"WindowsPhoneTrustedCertificate"=103;
"WindowsPhoneVPN"=104;
"WindowsDomainJoin"=105;
"WindowsDeliveryOptimization"=106;
"Windows10DeviceFirmwareConfigurationInterface"=107;
"WindowsHealthMonitoring"=108;
"Windows10XWifi"=109;
"Windows10XVPN"=110;
"Windows10XScep"=111;
"Windows10XTrustedCertificate"=112;
"SettingsCatalog"=113;
"SettingsCatalogWindows10X"=114;
"SettingsCatalogWindows10"=115;
"SettingsCatalogMacOS"=116;
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

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $result=Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        write-host "$($results.count) returned"
        $results=@()
        $results=$result.value

        if ($result."@odata.nextLink") {
            write-host "More results are available, will begin paging."
            $noMoreResults=$false
            do {

                #retrieve the next set of results
                $result=Invoke-RestMethod -Uri $result."@odata.nextLink" -Headers $authToken -Method Get -ErrorAction Continue
                $results+=$result.value

                #check if we need to continue paging
                If (-not $result."@odata.nextLink") {
                    $noMoreResults=$true
                    write-host "$($results.count) returned. No more pages."
                } else {
                    write-host "$($results.count) returned so far. Retrieving next page."
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
    param (
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
    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters).Result

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

function CheckAuthToken {
    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if($TokenExpires -le 1){
        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        $global:authToken = Get-AuthToken -User $user
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
    Write-error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    
    }

}

####################################################



# Checking if authToken exists before running authentication
If (-not $user) {
    $user=read-host "Enter your UPN"
    CheckAuthToken
}


$load=$true
$end=$false
$filter=$false

do {

    If ($load) {
        #Connect-MSGraph
        #$command=measure-command{$Configs=Get-IntuneDeviceConfigurationPolicy}

        CheckAuthToken
        $command=measure-command{$Configs=Get-DeviceConfigurationPolicy}
        $loadtime=get-date
        write-host "$($command.totalseconds) seconds to load"
        $load=$false

        $scopetags=get-roleScopeTags
        write-host "$($scopetags.count) scope tags returned"

        foreach ($profile in $Configs) {
            $type=$profile."@odata.type"
            $type=$type.replace("#microsoft.graph.","")
            $type=$type.replace("Configuration","")
            
            $profileTypeID=$profilesenum[$type]
            IF ($profileTypeID) {
                write-host "$type found as ID $profileTypeID"
    
                If ($type -eq "windowsUpdateForBusiness") {
                    $profile | add-member -notepropertyname URL -notepropertyvalue "https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/SoftwareUpdatesConfigurationMenuBlade/overview/configurationId/$($profile.id)/configurationName/Windows%20Update%20policy/softwareUpdatesType/windows"
                } else {
                    $profile | add-member -notepropertyname URL -notepropertyvalue "https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/ConfigurationMenuBlade/overview/configurationId/$($profile.id)/policyType/$profileTypeID/policyJourneyState/0"
                }
            } else {
                write-host "$type not found" -foregroundcolor "red"
            }
            
        }
    }

    If ($filter) {
        $filterscopetag=$scopetags | Out-GridView -PassThru
        $selected=$Configs|where-object {$_.roleScopeTagIds -contains $filterscopetag.id} | select displayName,id,"@odata.type",roleScopeTagIds, URL | Out-GridView -PassThru
    } else {
        $selected=$Configs|select displayName,id,"@odata.type",roleScopeTagIds, URL  | Out-GridView -PassThru
    }

    foreach ($profile in $selected) {
        IF ($profile.URL) {
            write-host "$($profile.URL) copied to clipboard"
            set-clipboard $profile.URL
        } else {
            write-host "URL not found" -foregroundcolor "red"
        }
        
    }

    $filter=$false
    write-host "`n`nList last loaded at $loadtime. select option`nx - exit`nr - reload`no - open list again`nf - filter list by scope tag"
    $result=read-host
    Switch ($result) {
        "x" {$end=$true}
        "r" {$load=$true}
        "o" {}
        "f" {$filter=$true}
    }

} until ($end)


