# Create Teams from SDS Groups
In March, SDS provisioning was changed to stop automatically creating Teams - https://docs.microsoft.com/en-us/schooldatasync/changes-to-class-teams-provisioning.
This sample script enumerates Office 365 Groups that were created using School Data Sync and creates a class team – replicating the functionality of SDS. The script only actions classes that are marked as active.


See https://github.com/scottbreenmsft/scripts/blob/master/SDS/CreateTeamsFromSDSGroups/Script%20-%20Create%20Teams%20for%20SDS%20Synchronised%20Groups.pdf for more information.

References:

https://docs.microsoft.com/en-us/graph/teams-create-group-and-team
