# Microsoft Autoupdate configuration

The Microsoft Autoupdate application on macOS is responsible for updating several Microsoft applications. The Microsoft Autoupdate application updates applications that are not installed from the macOS app store. Applications installed from the macOS app store are updated using the app store.

This article explains how you can set and minimise the configuration steps required by users for the Microsoft Autoupdate application when devices are managed by an MDM.

## Custom configuration

This Custom-Microsoft-Autoupdate.xml file contains an example file that can be used to configure the macOS Microsoft Autoupdate application. This file can be deployed to macOS devices using [Microsoft Intune custom profiles](https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-macos).

Below are the settings set by the sample configuration file:

| Setting Name | Setting Value | Reference |
| --- | --- | --- |
| ChannelName | Production | [Deploy updates for Microsoft Defender for Endpoint for Mac](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#set-the-channel-name) |
| HowToCheck | AutomaticDownload | [Deploy updates for Microsoft Defender for Endpoint for Mac](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#change-how-mau-interacts-with-updates) |
| DisableInsiderCheckbox | False | [Deploy updates for Microsoft Defender for Endpoint for Mac](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#disable-insider-checkbox) |
| SendAllTelemetryEnabled | True | [Deploy updates for Microsoft Defender for Endpoint for Mac](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/mac-updates#limit-the-telemetry-that-is-sent-from-mau) | 
| AcknowledgedDataCollectionPolicy | RequiredAndOptionalData | [Preference setting for the Required Data Notice dialog for Microsoft AutoUpdate](https://docs.microsoft.com/en-us/deployoffice/privacy/mac-privacy-preferences#preference-setting-for-the-required-data-notice-dialog-for-microsoft-autoupdate) |
