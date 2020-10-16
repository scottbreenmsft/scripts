Get-WindowsCapability -online -Name *en-au* | ft
$capabilities=Get-WindowsCapability -online -Name *en-au*
Foreach($capability in $capabilities) {
    IF ($capability.state -eq "NotPresent") {
        write-output "adding $($capability.name)"
        Add-WindowsCapability -Name $capability.name -online
    }
}
Get-WindowsCapability -online -Name *en-au* | ft
