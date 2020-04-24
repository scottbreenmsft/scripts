$tempuser="<enter a test user>"

Connect-MicrosoftTeams
Connect-azuread

#get SDS groups
$teams=get-azureadgroup -filter "extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Section'"

#filter list
$teams=$teams | where {$_.mailnickname -like "Section*"}
$teams=$teams | out-gridview -PassThru

#provide prompt
write-host "actioning $($teams.count) teams. continue? Enter to continue. Ctrl+C to exit"
read-host 
Write-Host "Continuing"

#monitor the progress
$progressCount=0

#action filtered teams
foreach ($team in $teams) {
    Write-Progress -Id 0 -PercentComplete $($progressCount/$($teams.count) * 100) -Activity "processing $($team.displayname)" -Status "$progressCount out of $($teams.count)";$progressCount++
    write-host "actioning $($team.displayName)"
    $users=get-teamuser -GroupId $team.objectid | where {$_.user -like "*@*" -and $_.role -eq "owner"}

    write-host "`tcurrent owners $($users.user -join ";")"

    #add temp owner
    If (-not ($users.count -ge 2)) {
        #add temp owner
        write-host "`tadding temp owner $tempuser to $($team.displayName)"
        add-teamuser -GroupId $team.objectid -User $tempuser -role Owner
    }

    #remove owner and re-add
    foreach ($user in $users) {
        write-host "`tremove $($user.user)"
        remove-teamuser -GroupId $team.objectid -User $user.user -role Owner

        write-host "`tadd $($user.user)"
        add-teamuser -GroupId $team.objectid -User $user.user -role Owner
    }

    #remove temp owner
    If (-not ($users.count -ge 2)) {
        write-host "`tremoving temp owner $tempuser from $($team.displayName)"
        remove-teamuser -GroupId $team.objectid -User $tempuser -role Owner
    }

}



