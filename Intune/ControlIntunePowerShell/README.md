## Limit access to Intune PowerShell
By default, once a Global Administrator approves the Intune PowerShell Azure AD Application for access to a tenant, all users are granted access. You can easily change the App Registration so that only users who are given access can use the application.

To limit user access, you can change the application to require user assignment. To do this:

1. Open the [Azure Active Directory Admin Console](http://aad.portal.azure.com)
2. Click on **Enterprise Applications**
3. Find and click on **Microsoft Intune PowerShell** in the list
4. Select **Properties**
5. Change **User assignment required?** to **Yes**
6. Click **Save**

### Add or remove users
To add or remove users of the Microsoft Intune PowerShell application:
1. Open the [Azure Active Directory Admin Console](http://aad.portal.azure.com)
2. Click on **Enterprise Applications**
3. Find and click on **Microsoft Intune PowerShell** in the list
4. Select **Users and groups**
5. Modify access as required
