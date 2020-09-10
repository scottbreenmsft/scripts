### Control access to Intune PowerShell
By default, once a Global Administrator consents for the [Microsoft Intune PowerShell](https://docs.microsoft.com/en-us/samples/microsoftgraph/powershell-intune-samples/intune-graph-samples/) Azure AD Application for access to a tenant, all users are granted access. Users who are granted access to the Microsoft Intune PowerShell app are still limited by their roles in [Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/directory-assign-admin-roles) or [Intune RBAC](https://docs.microsoft.com/en-us/mem/intune/fundamentals/role-based-access-control), but with access to PowerShell could perform bulk exports of data. You can easily change the App Registration so that only users who are given access can use the application.

#### Limit access
To limit user access, you can change the application to require user assignment. To do this:

1. Open the [Azure Active Directory Admin Console](http://aad.portal.azure.com).
2. Click on **Enterprise Applications**.
3. Find and click on **Microsoft Intune PowerShell** in the list.
4. Select **Properties**.
5. Change **User assignment required?** to **Yes**.
  ![Change User assignment required to Yes](https://github.com/scottbreenmsft/scripts/blob/master/Intune/ControlIntunePowerShell/Intune-PowerShell-User-Assignment.png)
6. Click **Save**.

#### Add or remove users
To add or remove users of the Microsoft Intune PowerShell application:
1. Open the [Azure Active Directory Admin Console](http://aad.portal.azure.com).
2. Click on **Enterprise Applications**.
3. Find and click on **Microsoft Intune PowerShell** in the list.
4. Select **Users and groups**.
5. Modify access as required.
  ![Add a user](https://github.com/scottbreenmsft/scripts/blob/master/Intune/ControlIntunePowerShell/Intune-PowerShell-Add-User.png)
