# Microsoft Autoupdate configuration

The Microsoft Autoupdate application on macOS is responsible for updating several Microsoft applications. The Microsoft Autoupdate application updates applications that are not installed from the macOS app store. Applications installed from the macOS app store are updated using the app store. The Microsoft Autoupdate application is automatically installed alongside:
 - Company Portal
 - Microsoft Edge
 - Microsoft Office
 - Microsoft OneDrive
 - Microsoft Defender for Endpoint for Mac

This article explains how you can set and minimise the configuration steps required by users for the Microsoft Autoupdate application when devices are managed by an MDM.

## Custom configuration

This **Custom-Microsoft-Autoupdate.xml** file contains an example file that can be used to configure the macOS Microsoft Autoupdate application. This file can be deployed to macOS devices using [Microsoft Intune custom profiles](https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-macos).

 - **Profile name**: Custom - Microsoft Autoupdate
 - **Configuration XML**: Custom-Microsoft-Autoupdate.xml


Below are the settings set by the sample configuration file:

| Setting Name | Setting Value | Reference |
| --- | --- | --- |
| ChannelName | Production | [Set preferences for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#set-the-channel-name) |
| HowToCheck | AutomaticDownload | [Set preferences for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#change-how-mau-interacts-with-updates) |
| DisableInsiderCheckbox | False | [Set preferences for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#disable-insider-checkbox) |
| SendAllTelemetryEnabled | True | [Set preferences for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#limit-the-telemetry-that-is-sent-from-mau) | 
| UpdateCheckFrequency | 720 | [Set preferences for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#set-update-check-frequency) | 
| AcknowledgedDataCollectionPolicy | RequiredAndOptionalData | This setting prevents Company Portal from prompting the user for data collection approval when opening for the first time. [Preference setting for the Required Data Notice dialog for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/deployoffice/privacy/mac-privacy-preferences#preference-setting-for-the-required-data-notice-dialog-for-microsoft-autoupdate) |
