
function InstallApp($packageFamilyName,$ApplicationID) {

    try {
        $session = New-CimSession
        $namespaceName = "root\cimv2\mdm\dmmap"

        # constructing the MDM instance and correct parameter for the 'StoreInstallMethod' function call
        $omaUri = "./Vendor/MSFT/EnterpriseModernAppManagement/AppInstallation"
        $newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance "MDM_EnterpriseModernAppManagement_AppInstallation01_01", $namespaceName
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ParentID", $omaUri, "string", "Key")
        $newInstance.CimInstanceProperties.Add($property)
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("InstanceID", $packageFamilyName, "String", "Key")
        $newInstance.CimInstanceProperties.Add($property)

        $flags = 0
        $paramValue = [Security.SecurityElement]::Escape($('<Application id="{0}" flags="{1}" skuid="{2}"/>' -f $applicationId, $flags, $skuId))
        $params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
        $param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", $paramValue, "String", "In")
        $params.Add($param)

        # we create the MDM instance and trigger the StoreInstallMethod to finally download the app
        $instance = $session.CreateInstance($namespaceName, $newInstance)
        $result = $session.InvokeMethod($namespaceName, $instance, "StoreInstallMethod", $params)
        write-output "...$packageFamilyName install triggered via MDM/StoreInstall method"

        #monitor company portal install
        $finish=$false
        Do {
            $status = $(Get-AppxPackage -Allusers | where-object{$_.packageFamilyName -Like $packageFamilyName}).Status
            if ($status -ne "Ok") {
                write-output "Waiting for $packageFamilyName to install - $status"
                start-sleep -seconds 60
            } else {
                write-output "$packageFamilyName installed"
                exit 0 
                $finish=$true
            }
        } while (-not $finish)

        #start-sleep -seconds 120
    }
    catch [Exception] {
        write-output $_ | out-string
        exit 1
    }
}


start-transcript C:\windows\temp\companyportal.log
$skuId = 0016

#ApplicationID generated from store URL - https://apps.microsoft.com/store/detail/company-portal/9WZDNCRFJ3PZ?hl=en-au&gl=AU
$applicationId = "9WZDNCRFJ3PZ" 
$packageFamilyName="Microsoft.CompanyPortal_8wekyb3d8bbwe"
$DependantProgramPackageFamilyName="Microsoft.Services.Store.Engagement_8wekyb3d8bbwe"

write-output "Triggering company portal install"
$app=Get-AppxPackage -Allusers | Where-Object {$_.packageFamilyName -eq $packageFamilyName}

#Company Portal is installed, but we need to check if a required component installed, otherwise we should reinstall Company Portal. 
#There have been reported instances of a reset resulting in company portal being installed but this component is missing
If ($app) {
    write-output "Company portal installed - $($app.status)"
    $app2=Get-AppxPackage -Allusers | Where-Object {$_.packageFamilyName -eq $DependantProgramPackageFamilyName}
    If ($app2) {
        write-output "$DependantProgramPackageFamilyName Installed"
        #continue
    } else {
        write-output "$DependantProgramPackageFamilyName Missing, need to remove company portal so that a reinstall triggers this component"
        Try {
            get-appxpackage -allusers | Where-Object {$_.packageFamilyName -eq $packageFamilyName} | remove-appxpackage -allusers
            $app = Get-AppxPackage -Allusers | Where-Object {$_.packageFamilyName -eq $packageFamilyName}
        } Catch {
            write-output $_ | out-string
        }
    }
}

#If Company Portal is not installed at this point, it's time to trigger the install
if (-not $app) {
    InstallApp $packageFamilyName $applicationId
} else {
    write-output "Company portal installed $($app.status)"
    exit 0
}

