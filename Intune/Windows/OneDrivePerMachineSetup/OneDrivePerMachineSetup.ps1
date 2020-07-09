If (-not (get-item "hklm:\SOFTWARE\Microsoft\OneDrive" -ErrorAction SilentlyContinue)) {
    $downloadURL="https://go.microsoft.com/fwlink/?linkid=844652"
    $outputfile="$env:temp\OneDriveSetup.exe"
    $eventSource = "My Scripts"
    New-EventLog -LogName Application -Source $eventSource -ErrorAction Ignore

    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "downloading from $downloadURL to $outputfile"
    Invoke-WebRequest -Uri $downloadURL -OutFile $outputfile
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "download complete"

    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "starting install"
    $proc=Start-Process $outputfile -ArgumentList "/allusers /silent" -Wait  -PassThru

    
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "install complete Exit code: $($proc.ExitCode)"
    exit $proc.ExitCode
} else {
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "OneDrive already installed per-machine"
}
