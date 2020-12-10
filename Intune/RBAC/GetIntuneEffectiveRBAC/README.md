# Summary
A tool to get the effective RBAC in Intune for a specified user.

The script will prompt you for administrator credentials and then the UPN of a user you want to check. The script will enumerate all the roles and role assignments within the Intune tenant and output the roles, role assignments, scope tags and Azure AD group that the user is in relevant to Intune RBAC.

The output will look like this if the user is in any role assignments:

GroupName|ScopeTags|RoleAssignment|Role
|---|---|---|---|       
|The Azure AD Group |The scope tags in the assignment|The assignment name|The role name|

### Example Output
```
user to check: kenm@bdoe.breenl.com

checking Policy and Profile manager

checking School Administrator
	Role assignment name: 1001
	Role assignment admin group IDs: aea96faa-b485-4579-8e9a-67704d5749f8
	User found in Azure AD Group 1001 - Admins

checking Help Desk Operator

checking Application Manager

checking Endpoint Security Manager

checking Read Only Operator

checking Intune Role Administrator

GroupName     ScopeTags RoleAssignment Role                
---------     --------- -------------- ----                
1001 - Admins 1001      1001           School Administrator
```
