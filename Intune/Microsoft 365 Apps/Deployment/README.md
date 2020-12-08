# Microsoft 365 App Deployment using Win32 apps

This article provides information about how to deploy Microsoft 365 Apps (including optional apps for Visio and Project) using an Intune Win32 app. 

**Why not use the built in Microsoft 365 Apps deployment?**

The build in tool for deploying Microsoft 365 Apps uses the Office CSP in Windows which does not have logic to allow for multiple targeting. This is relevant if you have a base install for Microsoft 365 Apps on a device but want to provide optional or more targetted installation of slight variations like adding Visio Standard, Project Professional, etc. In addition, the Office CSP does not have any user interaction capabiltiies. This is important because the installation of Office cannot be changed while any Office app is open, using the OFfice CSP you have the option of force closing the apps or failing if the apps are open.

| Feature | Built in tool | Custom Win32 app | 
| User interaction | No | Yes |
| Optional additional apps | No | Yes |
