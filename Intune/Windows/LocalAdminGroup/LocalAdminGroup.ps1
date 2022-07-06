#https://docs.microsoft.com/en-us/windows/client-management/mdm/using-powershell-scripting-with-the-wmi-bridge-provider
#Azure AD Joined Device Local Administrator
#
#Global Administrator
#
$WMIClass="MDM_Policy_Config01_LocalUsersAndGroups02"
$InstanceID="LocalUsersAndGroups"
#Import the System.Web class to encode the XML
Add-Type -AssemblyName System.Web
#Create the XML
$XML=[System.Web.HttpUtility]::HtmlEncode(@"
<GroupConfiguration>
<accessgroup desc = "Administrators">
    <group action = "R"/> 
        <add member = "Administrator"/>
        <add member = "S-1-12-1-3014515429-1245939445-1403750307-435716664"/>
        <add member = "S-1-12-1-32714429-1126888808-265143970-3628201436"/>
        <add member = "S-1-12-1-887949387-1179271642-3570471309-2659715508"/>
</accessgroup>
</GroupConfiguration>
"@)
#Apply the Configuration
$result=Get-CimInstance -Namespace 'root/cimv2/mdm/dmmap' -ClassName $WMIClass
If (-not $result) {
    $result = New-CimInstance -Namespace 'root/cimv2/mdm/dmmap' -ClassName $WMIClass -Property @{ParentId="./Vendor/MSFT/Policy/Config";InstanceId=$InstanceID;Configure=$XML}
} else {
    $result.Configure = $xml
    set-ciminstance -ciminstance $result
}
$result
