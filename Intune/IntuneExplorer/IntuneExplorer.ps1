
#https://docs.microsoft.com/en-us/graph/powershell/installation

Connect-MgGraph -Scopes @("Group.Read.All","DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All") -ContextScope Process
Select-MgProfile -Name "beta"
#Connect-MSGraph
#Get-MgDeviceManagementDeviceConfiguration -All -ExpandProperty assignments


#$Configs=Get-IntuneDeviceConfigurationPolicy -Expand assignments
write-host "Getting device config profiles"
$Configs=Get-MgDeviceManagementDeviceConfiguration -All -ExpandProperty assignments
#$Apps=Get-IntuneMobileApp -Expand assignments
write-host "Getting applications"
$Apps=Get-MgDeviceAppManagementMobileApp -All -Expand assignments
$ConfigAssignments= $Configs| Where-Object {$_.Assignments -ne "{}"}
$AppAssignments=$Apps | Where-Object {$_.Assignments -ne "{}"}

write-host "Processing configuration assignments"

$ConfigurationsWithGroups=@()

Foreach ($Config in $ConfigAssignments) {
    foreach ($Configassignment in $Config.assignments) {
        If ($Configassignment.target."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {
            $groupID= "AllDevices"
        }
        If ($Configassignment.target."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
            $groupID= "AllUsers"
        }
        If ($Configassignment.target."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
            $groupID= $Configassignment.target.groupId
        }

        $ConfigMapping = New-Object PSObject -Property @{
            GroupID=$groupID
            displayName=$Config.displayName
            ID=$Config.Id
            Type="Config"
        }
        $ConfigurationsWithGroups+=$ConfigMapping
    }
}

$GroupName=$null
$groupID=$null

write-host "Processing application assignments"
$Applications=@()

Foreach ($App in $AppAssignments) {
    foreach ($assignment in $app.assignments) {
        If ($assignment.target.AdditionalProperties."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {
            $groupID= "AllDevices"
        }
        If ($assignment.target.AdditionalProperties."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
            $groupID= "AllUsers"
        }
        If ($assignment.target.AdditionalProperties."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
            $groupID= $assignment.target.AdditionalProperties.groupId
        }

        $AppMapping = New-Object PSObject -Property @{
            GroupID=$groupID
            displayName=$App.displayName
            intent=$assignment.intent
            ID=$App.Id
            Type="App"
            AppType=$App.AdditionalProperties."@odata.type".replace("#microsoft.graph.","")
        }
        $Applications+=$AppMapping
    }
}

Function Get-Parents ($GroupID) {
    $GroupStructure=@()
    $GroupName=(Get-MgGroup -GroupID $GroupID).displayName
    $memberOf=Get-MgGroupMemberOf -GroupID $GroupID
    write-host "getting parents for $GroupName"
    $OneParent=$false
    Foreach ($parent in $memberOf) {
        If ($parent.additionalproperties."@odata.type" -eq "#microsoft.graph.group") {
            $OneParent=$true
            $Object = New-Object PSObject -Property @{
                GroupID=$GroupId
                GroupName=$GroupName
                Parent=$parent.id
            }
            $GroupStructure+=$Object
            write-host "Recursing to get $($parent.id)"
            $GroupStructure+=(Get-Parents $parent.id)
        }
    }
    If (-not $OneParent) {
        $Object = New-Object PSObject -Property @{
            GroupID=$GroupId
            GroupName=$GroupName
            Parent=$null
        }
        $GroupStructure+=$Object
    }
    return $GroupStructure
}
write-host "Processing group structure"
$GroupStructure=@()
$Groups=@()
$Groups=$Applications.GroupID | Where-Object {$_ -notin ('AllUsers','AllDevices')}
$Groups+=$ConfigurationsWithGroups.GroupID | Where-Object {$_ -notin ('AllUsers','AllDevices')}
$Groups=$Groups | select-object -unique
$memberOf=@()
Foreach ($Group in $Groups) {
    $GroupName=(Get-MgGroup -GroupID $Group).displayName
    $memberOf+=Get-Parents $group
}
$Object = New-Object PSObject -Property @{
    groupID= "AllDevices"
    groupname="All Devices"
    Parent=$null
}
$memberOf+=$Object
$Object = New-Object PSObject -Property @{
    groupID= "AllUsers"
    groupname="All Users"
    Parent=$null
}
$memberOf+=$Object
#$memberOf | ft *
#$Applications | ft displayName,GroupID,intent
$memberof=$memberof | select-object -unique GroupName,Parent,GroupID

function PrintList ($Group,$indent) {
    write-host "`n$indent$($Group.GroupName)"
    $PrintConfigs=$ConfigurationsWithGroups | where {$_.GroupID -eq $Group.GroupID}
    $PrintApps=$Applications | where {$_.GroupID -eq $Group.GroupID}
    IF ($PrintConfigs) {
        write-host "$indent`t=======CONFIG====="
    }
    Foreach ($PrintConfig in $PrintConfigs) {
        write-host "$indent`t$($PrintConfig.displayname)"
    }
    IF ($PrintApps) {
        write-host "$indent`t=======APPS======="
    }

    Foreach ($app in $PrintApps) {
        write-host "$indent`t$($app.displayname) - ($($app.AppType)) - $($app.intent)"
    }
    Foreach ($GroupObject in $($memberof | where {$_.parent -eq $Group.GroupID})) {
        PrintList -Group $GroupObject -Indent "$indent`t"
    }

}

$toplevel=$memberof | where {$_.Parent -eq $null}
Foreach ($Group in $toplevel) {
    PrintList -Group $Group -Indent ""
}

