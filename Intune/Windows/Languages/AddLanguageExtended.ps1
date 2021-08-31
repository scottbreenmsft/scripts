$geoId = 12  # Australia
$skuId = 0016
$inputLanguageID = "0c09:00000409" # en-US https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs
$locale = "en-au"
$languagepack = "en-GB"

#en-gb local experience packfamily name
$applicationId = "9nt52vq39bvn" #English GB https://www.microsoft.com/en-au/p/english-united-kingdom-local-experience-pack/9nt52vq39bvn
$packageFamilyName="Microsoft.LanguageExperiencePacken-GB_8wekyb3d8bbwe"

write-host "Triggering Local Experience pack install"
$status = $(Get-AppxPackage -Allusers | ? Name -Like *LanguageExperiencePacken-gb).Status
if ($status -ne "Ok") {
    try {
        $session = New-CimSession
        $namespaceName = "root\cimv2\mdm\dmmap"

        # constructing the MDM instance and correct parameter for the 'StoreInstallMethod' function call
        $omaUri = "./Vendor/MSFT/EnterpriseModernAppManagement/AppInstallation"
        $newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance "MDM_EnterpriseModernAppManagement_AppInstallation01_01", $namespaceName
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ParentID", $omaUri, "string", "Key")
        $newInstance.CimInstanceProperties.Add($property)
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("InstanceID", $packageFamilyName, "String", "Key")
        $newInstance.CimInstanceProperties.Add($property)

        $flags = 0
        $paramValue = [Security.SecurityElement]::Escape($('<Application id="{0}" flags="{1}" skuid="{2}"/>' -f $applicationId, $flags, $skuId))
        $params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
        $param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", $paramValue, "String", "In")
        $params.Add($param)

        # we create the MDM instance and trigger the StoreInstallMethod to finally download the LXP
        $instance = $session.CreateInstance($namespaceName, $newInstance)
        $result = $session.InvokeMethod($namespaceName, $instance, "StoreInstallMethod", $params)
        "...Language Experience Pack install process triggered via MDM/StoreInstall method"

        #start-sleep -seconds 120
    }
    catch [Exception] {
        write-host $_ | out-string
        #$exitcode = 1
    }
}

#trigger the install of Windows capabilities for the locale while the appx package installs
write-host "Installing Windows Capabiltiies for $locale"
Get-WindowsCapability -online -Name *$locale* | ft
$capabilities=Get-WindowsCapability -online -Name *$locale*
Foreach($capability in $capabilities) {
    IF ($capability.state -eq "NotPresent") {
        write-output "adding $($capability.name)"
        Add-WindowsCapability -Name $capability.name -online
    }
}

#monitor language experience pack install
$finish=$false
Do {
    $status = $(Get-AppxPackage -Allusers | ? Name -Like *LanguageExperiencePacken-gb).Status
    if ($status -ne "Ok") {
        write-host "Waiting for language experience pack to install"
        start-sleep -seconds 60
    } else {
        $finish=$true
    }
} while (-not $finish)

#Set keyboard list to en-au
write-host "Setting keyboard list to $locale"
Set-WinUserLanguageList $locale -Force

#set speech
write-host "setting speech to $locale in default user profile"
reg load HKLM\DefaultUser C:\Users\Default\NTUSER.DAT
reg add HKLM\DefaultUser\SOFTWARE\Microsoft\Speech_OneCore\Settings\SpeechRecognizer /v RecognizedLanguage /t reg_sz /d $locale
reg unload HKLM\DefaultUser
start-sleep -seconds 5

#Change new profile language options
write-host "Creating XML for international control panel applet"
$languageXml = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">

    <!-- user list -->
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
    </gs:UserList>

    <!-- GeoID -->
    <gs:LocationPreferences>
        <gs:GeoID Value="$geoId"/>
    </gs:LocationPreferences>

    <!-- UI Language Preferences -->
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="$languagepack"/>
    </gs:MUILanguagePreferences>

    <!-- system locale -->
    <gs:SystemLocale Name="$locale"/>

    <!-- input preferences -->
    <gs:InputPreferences>
        <gs:InputLanguageID Action="add" ID="$inputLanguageID" Default="true"/>
    </gs:InputPreferences>

    <!-- user locale -->
    <gs:UserLocale>
        <gs:Locale Name="$locale" SetAsCurrent="true" ResetAllSettings="false"/>
    </gs:UserLocale>

</gs:GlobalizationServices>
"@
$languageXmlPath = $(Join-Path -Path "c:\Windows" -ChildPath "CustomMUI.xml")

#Save content
write-host "Saving XML to $languageXml"
Out-File -FilePath $languageXmlPath -InputObject $languageXml -Encoding ascii

#execute command to set and copy language settings to default / welcome screen
write-host "Passing $languageXmlPath to international control panel applet"
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$languageXmlPath`""

