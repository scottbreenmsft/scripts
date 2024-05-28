# Windows Hello for Business

For Intune-managed devices you can configure Windows Hello for Business using two methods:
- **Tenant-wide.** The tenant wide Windows Hello for Business policies in Devices > Windows > Windows Enrollment > Windows Hello for Business. As a school, you may have disabled this previously to avoid students being asked to set up multi factor authentication on their phones.
- **Targeted using policies.** Targeted policies take precedence over the tenant-wide policy. This allows you to target Windows Hello for Business at groups of users or stage the rollout to reduce the operational impact.

For more information, see [Configure Windows Hello for Business](https://learn.microsoft.com/windows/security/identity-protection/hello-for-business/configure).

There are some optional configuration items relating to Windows Hello for Business that you might want to use as part of your deployment. Create these settings using a Windows custom policy.  For steps on creating a custom policy, see [Add custom settings for Windows 10/11 devices in Microsoft Intune](https://learn.microsoft.com/mem/intune/configuration/custom-settings-windows-10).
- **DisablePostLogonProvisioning** – This setting allows Windows Hello for Business to be enabled but prevents it from prompting the user to enable it during logon. Users can go into settings and enable it. 
  - **OMA-URI:** ./Device/Vendor/MSFT/PassportForWork/<Entra ID Tenant ID>/Policies/DisablePostLogonProvisioning
  - **Data type:** Boolean
  - **Value:** True
- **EnablePasswordlessExperience** - when the policy is enabled, certain Windows authentication scenarios don't offer users the option to use a password, helping organizations and preparing users to gradually move away from passwords. For more information, see Windows passwordless experience.
  - **OMA-URI:** ./Device/Vendor/MSFT/Policy/Config/Authentication/EnablePasswordlessExperience
  - **Data type:** int
  - **Value:** 1
