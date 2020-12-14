param ($installcommand)
start-transcript C:\windows\temp\ServiceUI.log
$NotificationCommand="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file Notification.ps1"
write-output $installcommand
write-output "version 14"

$targetprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='winword.exe'" -ErrorAction SilentlyContinue)
if ($targetprocesses.Count -eq 0) {
    Try {
        Write-Output "No user logged in, running without SerivuceUI"
        write-output "Running $installcommand"
        invoke-expression .\$installcommand
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
else {
    Foreach ($targetprocess in $targetprocesses) {
        $Username = $targetprocesses.GetOwner().User
        Write-output "$Username logged in, running with SerivuceUI"
    }
    Try {
        write-output "Attempting to run $notificationcommand"
        .\ServiceUI.exe -Process:explorer.exe C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file Notification.ps1
        write-output "Running $installcommand"
        invoke-expression .\$installcommand
        
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
Write-Output "Install Exit Code = $LASTEXITCODE"
Exit $LASTEXITCODE
