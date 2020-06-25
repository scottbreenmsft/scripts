#the vpp token file path
param (
    [ValidateScript({test-path $vppTokenFile})][Parameter(Mandatory=$true)][string]$vppTokenFile
)

function GetVppLicenses([string] $vppToken, $vppServiceConfig)
{
    $getLicensesRequest = @{
        "sToken" = $sTokenEncoded;
        "assignedOnly" = $true;
    }

    $batchToken = $null
    $sinceModifiedToken = $null
    $totalCount = $null

    $licenses = [System.Collections.ArrayList]@()
    do {
        $jsonGetLicensesRequest = $getLicensesRequest | ConvertTo-Json

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $getLicensesResponse = Invoke-WebRequest -Uri $vppServiceConfig.getLicensesSrvUrl -Method POST -Body $jsonGetLicensesRequest
        $ms = $sw.ElapsedMilliseconds

        if ($getLicensesResponse.StatusCode -ne 200) {
            throw "vpp get assets call failed: $getLicensesResponse.StatusCode"
        }

        $licensesResponse = ConvertFrom-Json $getLicensesResponse.Content

        # the first call usually only contains this..
        if ($licensesResponse.totalCount) {
            $totalCount = $licensesResponse.totalCount
        }

        # append the licenses
        if ($licensesResponse.licenses) {
            $licenses.AddRange($licensesResponse.licenses)
            Write-Host "[" $ms "ms ] got" $licensesResponse.licenses.Count "licenses; " $licenses.Count "/" $totalCount
        }

        $batchToken = $licensesResponse.batchToken
        $sinceModifiedToken = $licensesResponse.sinceModifiedToken

        # build the next request
        $getLicensesRequest = @{
            "sToken" = $sTokenEncoded;
            "assignedOnly" = $true;
            "batchToken" = $batchToken;
        }
    } until ($null -eq $batchToken -or $null -ne $sinceModifiedToken)

    return $licenses
}



function RevokeVppLicenses([string] $vppToken, $vppServiceConfig, [string] $adamIdStr, $serialnumbers)
{

    $serialJSON=$serialnumbers | ConvertTo-Json
    
    $revokeLicenseRequest = @{
        "sToken" = $sTokenEncoded;
        "adamIdStr" = $adamIdStr;
        "disassociateSerialNumbers" = $serialnumbers;
    }

    $jsonGetLicensesRequest = $revokeLicenseRequest | ConvertTo-Json
    $revokeLicensesResponse = Invoke-WebRequest -Uri $vppServiceConfig.manageVPPLicensesByAdamIdSrvUrl -Method POST -Body $jsonGetLicensesRequest

    if ($revokeLicensesResponse.StatusCode -ne 200) {
        throw "vpp get assets call failed: $($revokeLicensesResponse.StatusCode)"
    }

    $licensesResponse = ConvertFrom-Json $revokeLicensesResponse.Content

    return $licensesResponse

}

#get the vpp token
[string] $sTokenEncoded = Get-Content $vppTokenFile

#get VPP service parameters
$vppServiceConfigSrvUrl = "https://vpp.itunes.apple.com/mdm/VPPServiceConfigSrv"
$vppServiceConfigResponse = Invoke-WebRequest -Uri $vppServiceConfigSrvUrl -Method GET
if ($vppServiceConfigResponse.StatusCode -ne 200) {
    throw "vpp service config call failed: $vppServiceConfigResponse.StatusCode"
}

$vppServiceConfig = ConvertFrom-Json $vppServiceConfigResponse.Content

#get the vpp licenses current granted to this VPP token
IF ($vppServiceConfig) {
    $licenses = GetVppLicenses $sTokenEncoded $vppServiceConfig

    If ($licenses) {
        #prompt to select which licenses to revoke disassociate licenses for
        $appids=($licenses|group adamidstr|select @{n="AppID";e={$_.name}},@{n="Licenses";e={$_.count}} | Out-GridView -PassThru -title "Select 1 or more apps to revoke licenses for").AppID

        #enumerate through the applications selected and disassociate the serial numbers prompted by the licenses list
        foreach ($appID in $appids) {

            #Get the unique serial numbers that are currently associated
            $app=$licenses|where {$_.adamIdStr -eq $appID} | select serialnumber -Unique
            $serialnumbers=@($app.serialnumber)

            #if there are serial numbers to remove continue
            IF ($serialnumbers) {

                #prompt to confirm that we want to disassociate the licenses for this app
                If ((read-host "Do you want to disassociate all $($serialnumbers.count) licenses from $($appID)? (y to continue, anything else to cancel)") -EQ "y") {
    
                    #start a count for the batches
                    $doneCount=0

                    Do {
                        #perform the revoke in batches
                        $startNumber=$doneCount
                        $endNumber=$doneCount+($vppServiceConfig.maxBatchDisassociateLicenseCount)
                        If ($endNumber -gt ($serialnumbers.count-1)) {
                            $endNumber=$serialnumbers.count-1
                        }
                        $serialnumbersToAction=$serialnumbers[$startNumber..$endNumber]

                        #revoke the licenses for this batch
                        write-host "Attempting to revoke licenses for batch $($serialnumbersToAction -join ",")"
                        RevokeVppLicenses -vppToken $sTokenEncoded -vppServiceConfig $vppServiceConfig -adamIdStr $appID -serialnumbers $serialnumbersToAction
                
                        #it's possible we'll need to add a start-sleep -seconds 5 here if Apple starts denying frequent requests

                        #update the count
                        $doneCount=$endNumber

                    } until ($doneCount -ge ($serialnumbers.count-1))

                }

            }
        }
    }

}
