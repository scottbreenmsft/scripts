#requires -modules Microsoft.Graph.Intune

Connect-MsGraph
$VPPTokens=Get-DeviceAppManagement_VppTokens
write-host "Syncing $($VPPTokens.count) VPP tokens"
write-host "============================================"
foreach ($VPPToken in $VPPTokens) {
    write-host "Triggering sync for $($VPPToken.id)"
    $result=Invoke-DeviceAppManagement_VppTokens_SyncLicenses -vppTokenId $VPPToken.id
    write-host "Sleeping for 5 mins. Sleep started at $(get-date)" -foregroundcolor Gray
    Start-Sleep -Seconds (60*5)
}
