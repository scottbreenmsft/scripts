# Create Teams from SDS Groups
In March, SDS provisioning was changed to stop automatically creating Teams - https://docs.microsoft.com/en-us/schooldatasync/improved-class-and-roster-sync-for-teams.
This sample script enumerates Office 365 Groups that were created using School Data Sync and creates a class team – replicating the functionality of SDS. 


See https://github.com/scottbreenmsft/scripts/blob/master/SDS/CreateTeamsFromSDSGroups/Script%20-%20Create%20Teams%20for%20SDS%20Synchronised%20Groups.pdf for more information.

References:

https://docs.microsoft.com/en-us/graph/teams-create-group-and-team
https://docs.microsoft.com/en-us/graph/api/team-post?view=graph-rest-beta

Script update on 15th April 2020:
 - Updated to prompt which schools to provision classes for and provide progress indicators. This allows multiple sessions of the script to be run in separate powershell.exe processes to create teams as a multi threaded operation.
 - Records failed attempts and retries at the end of execution. The script will now output the failed class creations.
 - Updated to renew the auth token during the loop in case it expires while the script is attempting to create teams.
 - Removed the "Active" filter on the GetClassGroups function in case some schools are not syncing that attribute through SDS.
