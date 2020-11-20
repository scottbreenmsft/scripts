# Sync-AADAdminUnitMembership

If for some reason your organisation is unable to take advantage of [School Data Sync](https://docs.microsoft.com/en-us/schooldatasync/overview-of-school-data-sync) which can create and manage administrative units based on the data you synchronise, you can use this script to populate users in administrative units.

This sample script synchronises the user membership of an Administrative Unit with one or more groups based on name templates for the groups and administrative unit. The script will only add and remove users that have an @odata.type of #microsoft.graph.user.

The script is written under the assumption that the administrative unit and groups have attributes which contain the school code. This allows the script to match the groups against the adminitrative units without requiring a mapping file. 

Tested attributes:
 - Administrative Units
   - displayName
   - description
 - Groups
   - displayName
   - mail
   - mailnickname
   
**WARNING**

This script adds AND removes users so if the groups are found but are empty, the script will **remove** all users from the administrative unit. It's critical you test the script for you environment in a test environment, understand how it works and customise it for your needs before executing it in production.

## Script Parameters

 - **Tenant** - The domain name for your Azure tenant. eg. tenant.onmicrosoft.com.
 - **ClientID** - The Client ID of the Azure AD App Registration you'll use for authentication. Once the app registration is created, you can get the client ID using these instructions - [Get tenant and app ID values for signing in](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#get-tenant-and-app-id-values-for-signing-in).
 - **CertificateThumbprint** - The thumbprint of the certificate you're using for authentication.
 - **CertificateLocation** - The location of the certificate in the local certificate store.
 - **GroupNameTemplates** - An array of strings that contains the group names you want to sync with a the corresponding administrative unit. Use %SchoolCode% as the part of the string that will contain the School Code which is replaced during script execution.
 - **groupattribute** - The attribute on the groups to match the name against (eg. displayName, mail, mailNickname).
  - **AdminUnitTemnplate** - The name template for the administrative unit to look up for the school code. Use %SchoolCode% as the part of the string that will contain the School Code which is replaced during script execution.
  - **AdminUnitAttribute** - The attribute on administrative units to match against (i.e. description or displayName).
  - **SchoolCodes** - An array of strings that correspond to the school codes you want to action.

## Setup Azure AD Authentication

The script uses Azure AD App Registration and certificate authentication so that it can be set up as a scheduled task and run on a schedule. Using an App Registration and API permissions also allows you to constrain the permissions of the script to only read users, read groups and modify administrative units.

To set up the authentication for this script you will need a certificate (which can be self signed, in the certificate store of the user account running the task). 

### Step 1. Create app registration

Follow the steps in [Register an application with Azure AD and create a service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#register-an-application-with-azure-ad-and-create-a-service-principal)

### Step 2. Generate certificate and upload to app

Follow the steps in [Option 1: Upload a certificate](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-1-upload-a-certificate)

Update the script parameters:
 - **CertificateThumbprint** - The thumbprint of the certificate

### Step 3. Add API permissions

1. Go to your application in the **Azure portal – App registrations** experience
2. Locate the **API Permissions** section, and within the API permissions click **Add a permission**.
3. Select **Microsoft Graph** from the list of available APIs and then add the following permissions:
    - User.Read.All
    - Group.Read.All
    - AdministrativeUnit.ReadWrite.All
4. Save the permissions.
5. Grant admin consent for the permissions.

### Step 4. Update script parameters

Update the parameters as per the certificates and application that you created.
