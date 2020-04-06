# Create Teams from SDS Groups
In March, SDS provisioning was changed to stop automatically creating Teams - https://docs.microsoft.com/en-us/schooldatasync/changes-to-class-teams-provisioning.
This sample script enumerates Office 365 Groups that were created using School Data Sync and creates a class team – replicating the functionality of SDS. The script only actions classes that are marked as active.
