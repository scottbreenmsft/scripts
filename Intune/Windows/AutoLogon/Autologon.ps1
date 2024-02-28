$Username = "MyLocalUser"
$Password = "Password"
#$group = "Administrators"

$adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
$existing = $adsi.Children | where-object {$_.SchemaClassName -eq 'user' -and $_.Name -eq $Username}

if ($null -eq $existing) {
    Write-Host "Creating new local user $Username."
    & NET USER $Username $Password /add /y /expires:never

    #Write-Host "Adding local user $Username to $group."
    #& NET LOCALGROUP $group $Username /add

}else {
    Write-Host "Setting password for existing local user $Username."
    $existing.SetPassword($Password)
} 

Write-Host "Ensuring password for $Username never expires."
& WMIC USERACCOUNT WHERE "Name='$Username'" SET PasswordExpires=FALSE

REG.exe ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /t REG_SZ /d ".\$Username" /reg:64 /f
If ($Password -eq "") {
    REG.exe ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /reg:64 /f
}else{
    REG.exe ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /d "$Password" /reg:64 /f
}
REG.exe ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /t REG_SZ /d "1" /reg:64 /f

#When running in PPKG as part of OOBE, create a scheduled task to reset key values.
#Otherwise the PPKG turns off subsequent autologons.
If ($env:USERNAME -eq "defaultuser0") {
    $trigger=New-ScheduledTaskTrigger -AtLogOn
    If ($Password -eq "") {
        $Action1=New-ScheduledTaskAction -execute "C:\windows\system32\REG.exe" -argument "ADD `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v `"DefaultPassword`" /t REG_SZ /reg:64 /f"
    } else {
        $Action1=New-ScheduledTaskAction -execute "C:\windows\system32\REG.exe" -argument "ADD `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v `"DefaultPassword`" /t REG_SZ /d `"$Password`" /reg:64 /f"
    }
    $Action2=New-ScheduledTaskAction -execute "C:\windows\system32\REG.exe" -argument "ADD `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v `"AutoAdminLogon`" /t REG_SZ /d `"1`" /reg:64 /f"
    $Action3=New-ScheduledTaskAction -Execute "C:\windows\system32\schtasks.exe" -argument "/delete /tn `"Setup Autologon`" /f"
    Register-ScheduledTask -Trigger $trigger -Action @($action1,$action2,$action3) -TaskName "Setup Autologon" -RunLevel Highest
    $principal = New-ScheduledTaskPrincipal -UserID SYSTEM `
        -LogonType ServiceAccount  -RunLevel Highest
    Set-ScheduledTask -TaskName "Setup Autologon" -Principal $principal
}
