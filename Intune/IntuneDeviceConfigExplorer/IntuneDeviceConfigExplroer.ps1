#requires -modules Microsoft.Graph.Intune
##########################################
#Install required modules using local admin and following command:
#Install-Module Microsoft.Graph.Intune
##########################################


$profilesenum=@{
"AndroidCustom"=1;
"AndroidEmailProfile"=2;
"AndroidDeviceOwnerGeneral"=3;
"AndroidDeviceOwnerDerivedCredentialAppAuthenticationConfiguration"=4;
"AndroidDeviceOwnerImportedPFX"=5;
"AndroidDeviceOwnerPKCS"=6;
"AndroidDeviceOwnerSCEP"=7;
"AndroidDeviceOwnerTrustedCertificate"=8;
"AndroidDeviceOwnerVpn"=9;
"AndroidDeviceOwnerWiFi"=10;
"AndroidForWorkCustom"=11;
"AndroidForWorkEmailProfile"=12;
"AndroidForWorkVpn"=13;
"AndroidForWorkGeneral"=14;
"AndroidForWorkImportedPFX"=15;
"AndroidForWorkOemConfig"=16;
"AndroidForWorkPKCS"=17;
"AndroidForWorkSCEP"=18;
"AndroidForWorkTrustedCertificate"=19;
"AndroidForWorkWiFi"=20;
"AndroidGeneral"=21;
"AndroidImportedPFX"=22;
"AndroidPKCS"=23;
"AndroidSCEP"=24;
"AndroidTrustedCertificate"=25;
"AndroidVPN"=26;
"AndroidWiFi"=27;
"AndroidZebraMx"=28;
"AOSPDeviceOwnerDevice"=29;
"ComplianceAndroid"=30;
"ComplianceAndroidForWork"=31;
"ComplianceAndroidDeviceOwner"=32;
"ComplianceAOSPDeviceOwner"=33;
"ComplianceIos"=34;
"ComplianceMac"=35;
"ComplianceWindows10"=36;
"ComplianceWindows10Mobile"=37;
"ComplianceWindows8"=38;
"ComplianceWindowsPhone"=39;
"ComplianceDefaultPolicy"=40;
"IosCustom"=41;
"IosDeviceFeatures"=42;
"IosDerivedCredentialAuthenticationConfiguration"=43;
"IosEducation"=44;
"IosEmailProfile"=45;
"IosGeneralDevice"=46;
"IosImportedPFX"=47;
"IosPKCS"=48;
"IosPresets"=49;
"IosSCEP"=50;
"IosTrustedCertificate"=51;
"IosUpdate"=52;
"IosVPN"=53;
"IosWiFi"=54;
"IosExpeditedCheckin"=55;
"MacOSCustom"=56;
"MacCustomPreferences"=57;
"MacOSDeviceFeatures"=58;
"MacEndpointProtection"=59;
"MacExtensions"=60;
"MacGeneral"=61;
"MacImportedPFX"=62;
"MacSCEP"=63;
"MacOSPKCS"=64;
"MacTrustedCertificate"=65;
"MacVPN"=66;
"MacWiFi"=67;
"MacWiredNetwork"=68;
"MacOSSoftwareUpdate"=69;
"Unsupported"=70;
"Windows10AdministrativeTemplate"=71;
"Windows10Atp"=72;
"Windows10AtpStreamlinedOnboarding"=73;
"Windows10Custom"=74;
"Windows10DesktopSoftwareUpdate"=75;
"Windows10EmailProfile"=76;
"Windows10EndpointProtection"=77;
"Windows10EnterpriseDataProtection"=78;
"Windows10General"=79;
"Windows10Kiosk"=80;
"Windows10PolicyOverride"=81;
"Windows10PKCS"=82;
"Windows10ImportedPFX"=83;
"Windows10SCEP"=84;
"Windows10SecureAssessmentProfile"=85;
"SharedPC"=86;
"Windows10TeamGeneral"=87;
"Windows10TrustedCertificate"=88;
"Windows10VPN"=89;
"Windows10WiFi"=90;
"Windows10NetworkBoundary"=91;
"Windows8General"=92;
"Windows8SCEP"=93;
"Windows8TrustedCertificate"=94;
"Windows8VPN"=95;
"Windows8WiFi"=96;
"WindowsEditionUpgrade"=97;
"WindowsIdentityProtection"=98;
"WindowsPhoneCustom"=99;
"WindowsPhoneEmailProfile"=100;
"WindowsPhoneGeneral"=101;
"WindowsPhoneImportedPFX"=102;
"WindowsPhoneSCEP"=103;
"WindowsPhoneTrustedCertificate"=104;
"WindowsPhoneVPN"=105;
"WindowsDomainJoin"=106;
"WindowsDeliveryOptimization"=107;
"Windows10DeviceFirmwareConfigurationInterface"=108;
"WindowsHealthMonitoring"=109;
"Windows10XWifi"=110;
"Windows10XVPN"=111;
"Windows10XScep"=112;
"Windows10XTrustedCertificate"=113;
"SettingsCatalog"=114;
"SettingsCatalogWindows10X"=115;
"SettingsCatalogWindows10"=116;
"SettingsCatalogMacOS"=117;
}


$load=$true
$end=$false

do {

    If ($load) {
        Connect-MSGraph
        $command=measure-command{$Configs=Get-IntuneDeviceConfigurationPolicy}
        $loadtime=get-date
        write-host "$($command.seconds) seconds to load"
        $load=$false
    }

    $selected=$Configs|select displayName,id,"@odata.type"  | Out-GridView -PassThru
    foreach ($profile in $selected) {
        $type=$profile."@odata.type"
        $type=$type.replace("#microsoft.graph.","")
        $type=$type.replace("Configuration","")
        
        $profileTypeID=$profilesenum[$type]
        IF ($profileTypeID) {
            write-host "$type found as ID $profileTypeID"
            $URL="https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/ConfigurationMenuBlade/overview/configurationId/$($profile.id)/policyType/$profileTypeID/policyJourneyState/0"
            write-host "URL copied to clipboard" -ForegroundColor "yellow"
            set-clipboard $URL
        } else {
            write-host "$type not found" -foregroundcolor "red"
        }
        
    }

    write-host "`n`nList last loaded at $loadtime. select option`nx - exit`nr - reload`no - open list again"
    $result=read-host
    Switch ($result) {
        "x" {$end=$true}
        "r" {$load=$true}
        "o" {}
    }


} until ($end)


