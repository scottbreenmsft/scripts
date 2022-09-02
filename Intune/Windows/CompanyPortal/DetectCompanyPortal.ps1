$packageFamilyName="Microsoft.CompanyPortal_8wekyb3d8bbwe"
$app=Get-AppxPackage -Allusers | Where-Object {$_.packageFamilyName -eq $packageFamilyName}
if (-not $app) {
    write-output "Not installed"
    exit 1
} else {
    write-output "Company Portal Installed - $($app.status)"

    #confirmed required component installed
    $app2=Get-AppxPackage -Allusers | Where-Object {$_.packageFamilyName -eq "Microsoft.Services.Store.Engagement_8wekyb3d8bbwe"}
    If ($app2) {
        write-output "Microsoft.Services.Store.Engagement Installed"
        exit 0
    } else {
        write-output "Microsoft.Services.Store.Engagement Missing"
        exit 1
    }
    exit 0
}
