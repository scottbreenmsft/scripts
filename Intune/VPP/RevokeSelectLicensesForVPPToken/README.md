# Revoke Select Licenses For VPPToken

This script allows you to connect directly to the Apple VPP service using your VPP token to selectively revoke all licenses for 1 or more selected apps. You will need to download the VPP token from Apple School Manager / Apple Business Manager and enter the path to the file when the script prompts.

The AppIDs shown in the grid view correspond to the App ID in the Apple app url (eg. https://apps.apple.com/au/app/**<appname\>**/id\<appid\>). You can get this ID using the Graph API or by getting the **Information URL** in the Microsoft Endpoint Mangaer console.

For reference, see https://developer.apple.com/documentation/devicemanagement/managevpplicensesbyadamidrequest
