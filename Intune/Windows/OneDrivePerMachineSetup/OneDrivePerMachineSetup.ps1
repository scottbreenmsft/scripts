$ScriptName="OneDriveSetupMachineInstall.ps1"

#variables
$eventSource = "My Scripts"

#create an event log source to store the events
New-EventLog -LogName Application -Source $eventSource -ErrorAction Ignore

#check if onedrive machine setup is already installed
If (-not (get-itempropertyvalue -PATH "hklm:\SOFTWARE\Microsoft\OneDrive\" -NAME "CurrentVersionPath" -ErrorAction SilentlyContinue)) {

    #more variables
    $downloadURL="https://go.microsoft.com/fwlink/?linkid=844652"
    $outputfile="$env:temp\OneDriveSetup.exe"

    #download the file
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : downloading from $downloadURL to $outputfile"
    Invoke-WebRequest -Uri $downloadURL -OutFile $outputfile
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "$ScriptName : Download complete"

    #check if onedrivesetup is already running
    If (get-process onedrivesetup -ErrorAction SilentlyContinue) {
        Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : OneDrive setup already running, waiting 30 seconds."
        $finished=$false
        $count=0
        do {
            start-sleep -Seconds 30
            If (get-process onedrivesetup -ErrorAction SilentlyContinue) {
                $count++
                Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : OneDrive setup already running, waiting 30 seconds. Waited $count times"
            } else {
                $finished=$true
            }
        } until ($finished -or ($count -ge 10))
    }
   

    #start setup
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "$ScriptName : Starting install"
    $proc=Start-Process $outputfile -ArgumentList "/allusers /silent" -Wait -PassThru
    
    start-sleep -Seconds 30

    #wait for setup to complete (sometimes it creates additional processes to complete setup)
    If (get-process onedrivesetup -ErrorAction SilentlyContinue) {
        Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : OneDrive setup still running, waiting 30 seconds."
        $finished=$false
        $count=0
        do {
            start-sleep -Seconds 30
            If (get-process onedrivesetup -ErrorAction SilentlyContinue) {
                $count++
                Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : OneDrive setup still running, waiting 30 seconds. Waited $count times"
            } else {
                $finished=$true
            }
        } until ($finished -or ($count -ge 10))
    }
    
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message  "$ScriptName : install complete Exit code: $($proc.ExitCode)"
    exit $proc.ExitCode
} else {
    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 3 -message "$ScriptName : OneDrive already installed per-machine"
}
