<#
.SYNOPSIS
    Identifies clients that are not covered by a Boundary Group.

.DESCRIPTION
    Uses information from the Configuration Manager database to determine if there are clients that are not covered by a Boundary Group. The script will attempt to display relevant information for clients not covered by a Boundary Group to allow an administrator to decide if Boundary configuration needs to be updated.

    The determines whether a Boundary Group has content by confirming there is a site system specified on the references tab - it doesn't currently check to ensure that system actually has the Distribution Point role installed.

    The list ranges option of the script has some bugs that cause it to list clients as not being covered by a Boundary Group. I wouldn't recommend using that feature unless you know how to fix the code :)

.PARAMETER ServerName
    The name of the server that runs the SMS provider of the site you want to check. This is usually the CAS or Primary Site Server.

.PARAMETER ListRanges
    This parameter will (eventually) list possible IP ranges for clients that could be used to create IP range boundaries. This code is currently experimental and doesn't work as designed.

.PARAMETER Path
    This is the path where you could like to export the CSV to. eg. C:\export.csv

.EXAMPLE
    .\GetCMClientToBoundaryGroupConfiguration.ps1 -servername CMSERVER

    References:
    http://www.scconfigmgr.com/2014/04/15/check-if-an-ip-address-is-within-an-ip-range-boundary-in-configmgr-2012/
    https://msdn.microsoft.com/en-us/library/hh949298.aspx
    http://www.powershelladmin.com/wiki/Calculate_and_enumerate_subnets_with_PSipcalc#Download_PSipcalc

    CHANGE HISTORY
    Version    Description
    0.1        Initial version    
    0.2        Added ability to list possible IP ranges
    0.3        Efficiency improvements
    0.4        Updated to detect the difference between site assignment and content only boundaries
               Auto provide possible IP range if device is not covered by a content boundary group
    0.5        Updated before final release
#>

param ($ServerName=$(Read-Host "Enter the name of the server with the SMS Provider installed (usually a CAS or Primary Site Server)"),
$listranges=$false,
$path="$($env:temp)\BoundaryCheck.csv")

#fucntion Get-CMSiteCode
function Get-CMSiteCode ($SiteServer) {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}


##functions from http://www.powershelladmin.com/wiki/Calculate_and_enumerate_subnets_with_PSipcalc#Download_PSipcalc
# This is a regex I made to match an IPv4 address precisely ( http://www.powershelladmin.com/wiki/PowerShell_regex_to_accurately_match_IPv4_address_%280-255_only%29 )
$IPv4Regex = '(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)'

function Convert-IPToBinary
{
    param(
        [string] $IP
    )
    $IP = $IP.Trim()
    if ($IP -match "\A${IPv4Regex}\z")
    {
        try
        {
            return ($IP.Split('.') | ForEach-Object { [System.Convert]::ToString([byte] $_, 2).PadLeft(8, '0') }) -join ''
        }
        catch
        {
            Write-Warning -Message "Error converting '$IP' to a binary string: $_"
            return $Null
        }
    }
    else
    {
        Write-Warning -Message "Invalid IP detected: '$IP'."
        return $Null
    }
}

function Convert-BinaryToIP
{
    param(
        [string] $Binary
    )
    $Binary = $Binary -replace '\s+'
    if ($Binary.Length % 8)
    {
        Write-Warning -Message "Binary string '$Binary' is not evenly divisible by 8."
        return $Null
    }
    [int] $NumberOfBytes = $Binary.Length / 8
    $Bytes = @(foreach ($i in 0..($NumberOfBytes-1))
    {
        try
        {
            #$Bytes += # skipping this and collecting "outside" seems to make it like 10 % faster
            [System.Convert]::ToByte($Binary.Substring(($i * 8), 8), 2)
        }
        catch
        {
            Write-Warning -Message "Error converting '$Binary' to bytes. `$i was $i."
            return $Null
        }
    })
    return $Bytes -join '.'
}

function Get-ProperCIDR
{
    param(
        [string] $CIDRString
    )
    $CIDRString = $CIDRString.Trim()
    $o = '' | Select-Object -Property IP, NetworkLength
    if ($CIDRString -match "\A(?<IP>${IPv4Regex})\s*/\s*(?<NetworkLength>\d{1,2})\z")
    {
        # Could have validated the CIDR in the regex, but this is more informative.
        if ([int] $Matches['NetworkLength'] -lt 0 -or [int] $Matches['NetworkLength'] -gt 32)
        {
            Write-Warning "Network length out of range (0-32) in CIDR string: '$CIDRString'."
            return
        }
        $o.IP = $Matches['IP']
        $o.NetworkLength = $Matches['NetworkLength']
    }
    elseif ($CIDRString -match "\A(?<IP>${IPv4Regex})[\s/]+(?<SubnetMask>${IPv4Regex})\z")
    {
        $o.IP = $Matches['IP']
        $SubnetMask = $Matches['SubnetMask']
        if (-not ($BinarySubnetMask = Convert-IPToBinary $SubnetMask))
        {
            return # warning displayed by Convert-IPToBinary, nothing here
        }
        # Some validation of the binary form of the subnet mask, 
        # to check that there aren't ones after a zero has occurred (invalid subnet mask).
        # Strip all leading ones, which means you either eat 32 1s and go to the end (255.255.255.255),
        # or you hit a 0, and if there's a 1 after that, we've got a broken subnet mask, amirite.
        if ((($BinarySubnetMask) -replace '\A1+') -match '1')
        {
            Write-Warning -Message "Invalid subnet mask in CIDR string '$CIDRString'. Subnet mask: '$SubnetMask'."
            return
        }
        $o.NetworkLength = [regex]::Matches($BinarySubnetMask, '1').Count
    }
    else
    {
        Write-Warning -Message "Invalid CIDR string: '${CIDRString}'. Valid examples: '192.168.1.0/24', '10.0.0.0/255.0.0.0'."
        return
    }
    # Check if the IP is all ones or all zeroes (not allowed: http://www.cisco.com/c/en/us/support/docs/ip/routing-information-protocol-rip/13788-3.html )
    if ($o.IP -match '\A(?:(?:1\.){3}1|(?:0\.){3}0)\z')
    {
        Write-Warning "Invalid IP detected in CIDR string '${CIDRString}': '$($o.IP)'. An IP can not be all ones or all zeroes."
        return
    }
    return $o
}

# Not used.
function Get-IPRange
{
    param(
        [string] $StartBinary,
        [string] $EndBinary
    )
    $StartIPArray = @((Convert-BinaryToIP $StartBinary) -split '\.')
    $EndIPArray = ((Convert-BinaryToIP $EndBinary) -split '\.')
    Write-Verbose -Message "Start IP: $($StartIPArray -join '.')"
    Write-Verbose -Message "End IP: $($EndIPArray -join '.')"
    $FirstOctetArray = @($StartIPArray[0]..$EndIPArray[0])
    $SecondOctetArray = @($StartIPArray[1]..$EndIPArray[1])
    $ThirdOctetArray = @($StartIPArray[2]..$EndIPArray[2])
    $FourthOctetArray = @($StartIPArray[3]..$EndIPArray[3])
    # Four levels of nesting... Slow.
    $IPs = @(foreach ($First in $FirstOctetArray)
    {
        foreach ($Second in $SecondOctetArray)
        {
            foreach ($Third in $ThirdOctetArray)
            {
                foreach ($Fourth in $FourthOctetArray)
                {
                    "$First.$Second.$Third.$Fourth"
                }
            }
        }
    })
    $IPs = $IPs | Sort-Object -Unique -Property @{Expression={($_ -split '\.' | ForEach-Object { '{0:D3}' -f [int]$_ }) -join '.' }}
    return $IPs
}

# Used. ;)
function Get-IPRange2
{
    param(
        [string] $StartBinary,
        [string] $EndBinary
    )
    [int64] $StartInt = [System.Convert]::ToInt64($StartBinary, 2)
    [int64] $EndInt = [System.Convert]::ToInt64($EndBinary, 2)
    for ($BinaryIP = $StartInt; $BinaryIP -le $EndInt; $BinaryIP++)
    {
        Convert-BinaryToIP ([System.Convert]::ToString($BinaryIP, 2).PadLeft(32, '0'))
    }
}

function Test-IPIsInNetwork {
    param(
        [string] $IP,
        [string] $StartBinary,
        [string] $EndBinary
    )
    $TestIPBinary = Convert-IPToBinary $IP
    [int64] $TestIPInt64 = [System.Convert]::ToInt64($TestIPBinary, 2)
    [int64] $StartInt64 = [System.Convert]::ToInt64($StartBinary, 2)
    [int64] $EndInt64 = [System.Convert]::ToInt64($EndBinary, 2)
    if ($TestIPInt64 -ge $StartInt64 -and $TestIPInt64 -le $EndInt64)
    {
        return $True
    }
    else
    {
        return $False
    }
}

function Get-NetworkInformationFromProperCIDR
{
    param(
        [psobject] $CIDRObject
    )
    $o = '' | Select-Object -Property IP, NetworkLength, SubnetMask, NetworkAddress, HostMin, HostMax, 
        Broadcast, UsableHosts, TotalHosts, IPEnumerated, BinaryIP, BinarySubnetMask, BinaryNetworkAddress,
        BinaryBroadcast
    $o.IP = [string] $CIDRObject.IP
    $o.BinaryIP = Convert-IPToBinary $o.IP
    $o.NetworkLength = [int32] $CIDRObject.NetworkLength
    $o.SubnetMask = Convert-BinaryToIP ('1' * $o.NetworkLength).PadRight(32, '0')
    $o.BinarySubnetMask = ('1' * $o.NetworkLength).PadRight(32, '0')
    $o.BinaryNetworkAddress = $o.BinaryIP.SubString(0, $o.NetworkLength).PadRight(32, '0')
    if ($Contains)
    {
        if ($Contains -match "\A${IPv4Regex}\z")
        {
            # Passing in IP to test, start binary and end binary.
            return Test-IPIsInNetwork $Contains $o.BinaryNetworkAddress $o.BinaryNetworkAddress.SubString(0, $o.NetworkLength).PadRight(32, '1')
        }
        else
        {
            Write-Error "Invalid IPv4 address specified with -Contains"
            return
        }
    }
    $o.NetworkAddress = Convert-BinaryToIP $o.BinaryNetworkAddress
    if ($o.NetworkLength -eq 32 -or $o.NetworkLength -eq 31)
    {
        $o.HostMin = $o.IP
    }
    else
    {
        $o.HostMin = Convert-BinaryToIP ([System.Convert]::ToString(([System.Convert]::ToInt64($o.BinaryNetworkAddress, 2) + 1), 2)).PadLeft(32, '0')
    }
    #$o.HostMax = Convert-BinaryToIP ([System.Convert]::ToString((([System.Convert]::ToInt64($o.BinaryNetworkAddress.SubString(0, $o.NetworkLength)).PadRight(32, '1'), 2) - 1), 2).PadLeft(32, '0'))
    #$o.HostMax = 
    [string] $BinaryBroadcastIP = $o.BinaryNetworkAddress.SubString(0, $o.NetworkLength).PadRight(32, '1') # this gives broadcast... need minus one.
    $o.BinaryBroadcast = $BinaryBroadcastIP
    [int64] $DecimalHostMax = [System.Convert]::ToInt64($BinaryBroadcastIP, 2) - 1
    [string] $BinaryHostMax = [System.Convert]::ToString($DecimalHostMax, 2).PadLeft(32, '0')
    $o.HostMax = Convert-BinaryToIP $BinaryHostMax
    $o.TotalHosts = [int64][System.Convert]::ToString(([System.Convert]::ToInt64($BinaryBroadcastIP, 2) - [System.Convert]::ToInt64($o.BinaryNetworkAddress, 2) + 1))
    $o.UsableHosts = $o.TotalHosts - 2
    # ugh, exceptions for network lengths from 30..32
    if ($o.NetworkLength -eq 32)
    {
        $o.Broadcast = $Null
        $o.UsableHosts = [int64] 1
        $o.TotalHosts = [int64] 1
        $o.HostMax = $o.IP
    }
    elseif ($o.NetworkLength -eq 31)
    {
        $o.Broadcast = $Null
        $o.UsableHosts = [int64] 2
        $o.TotalHosts = [int64] 2
        # Override the earlier set value for this (bloody exceptions).
        [int64] $DecimalHostMax2 = [System.Convert]::ToInt64($BinaryBroadcastIP, 2) # not minus one here like for the others
        [string] $BinaryHostMax2 = [System.Convert]::ToString($DecimalHostMax2, 2).PadLeft(32, '0')
        $o.HostMax = Convert-BinaryToIP $BinaryHostMax2
    }
    elseif ($o.NetworkLength -eq 30)
    {
        $o.UsableHosts = [int64] 2
        $o.TotalHosts = [int64] 4
        $o.Broadcast = Convert-BinaryToIP $BinaryBroadcastIP
    }
    else
    {
        $o.Broadcast = Convert-BinaryToIP $BinaryBroadcastIP
    }
    # I had to create this Get-IPRange function because a 32-digit binary number wouldn't fit in an int64...
    ### no, I didn't... Get-IPRange2 in effect; significantly faster.
    if ($Enumerate)
    {
        $IPRange = @(Get-IPRange2 $o.BinaryNetworkAddress $o.BinaryNetworkAddress.SubString(0, $o.NetworkLength).PadRight(32, '1'))
        if ((31, 32) -notcontains $o.NetworkLength )
        {
            $IPRange = $IPRange[1..($IPRange.Count-1)] # remove first element
            $IPRange = $IPRange[0..($IPRange.Count-2)] # remove last element
        }
        $o.IPEnumerated = $IPRange
    }
    else {
        $o.IPEnumerated = @()
    }
    return $o
}



#get the site code from the SMS provider
$sitecode=Get-CMSiteCode $ServerName

#get the boundaries from the SMS provider
write-host "getting boundaries"
$boundaries=get-wmiobject  -Namespace "root\sms\site_$sitecode" -Class "SMS_Boundary" -ComputerName $ServerName



#get boundary groups
write-host "getting boundary groups"
$boundaryGroups=get-wmiobject  -Namespace "root\sms\site_$sitecode" -Class "SMS_BoundaryGroup" -ComputerName $ServerName

#foreach boundary, find boundary group with distribuiton points, change to "yes" for content, add to string, add site code to boundary
#list clients that have more than one boundaruy
$SiteSystems=get-wmiobject  -Namespace "root\sms\site_$sitecode" -Class "SMS_SystemResourceList" -ComputerName $ServerName -filter "rolename='SMS Distribution Point'"
$boundaryGroupSiteSystems=get-wmiobject  -Namespace "root\sms\site_$sitecode" -Class "SMS_BoundaryGroupSiteSystems" -ComputerName $ServerName
$boundaryGroupMembers=get-wmiobject  -Namespace "root\sms\site_$sitecode" -Class "SMS_BoundaryGroupMembers" -ComputerName $ServerName
$countb=0
write-host "enumerating $($boundaries.count)"
foreach ($boundary in $boundaries) {
    write-progress -id 2 -activity $boundary.value -status "$countb of $(@($boundaries).count)" -percentcomplete ($countb/@($boundaries).count*100);$countb++
    If ($countb % 10 -eq 10) {
        write-host "$countb out of $(@($boundaries).count)"
    }
    $blnHasContent=$false
    $GroupNamesContent=@()
    $GroupNamesAssignmentOnly=@()
    $SiteCodes=@()
    $FilteredBoundaryGroupIDs=$boundaryGroupMembers | where {$_.boundaryid -eq $Boundary.boundaryid}
    foreach ($boundaryid in $FilteredBoundaryGroupIDs) {
        $DPs=@()
        $FilteredBoundaryGroupSiteSystemMembers=$boundaryGroupSiteSystems | where {$_.GroupID -eq $boundaryid.groupid}
        Foreach ($siteSystemNAL in $FilteredBoundaryGroupSiteSystemMembers) {
            $siteSystem=$sitesystems | where {$_.nalpath -eq $siteSystemNAL.ServerNALPath}
            If ($siteSystem) {
                $DPs+=$siteSystem.ServerRemoteName
            }
        }

        $FilteredBoundaryGroup=$boundaryGroups | where {$_.groupid -eq $boundaryid.groupid}
        If ($DPs) {
            $blnHasContent=$true
            $GroupNamesContent+= $FilteredBoundaryGroup.name
        }
        If ($FilteredBoundaryGroup.defaultsitecode -ne $null) {
            $SiteCodes+= $FilteredBoundaryGroup.DefaultSiteCode
            $GroupNamesAssignmentOnly+=$FilteredBoundaryGroup.name
        }
        

    }
    $boundary | add-member -NotePropertyName DPs -NotePropertyValue $blnHasContent -Force
    $boundary | add-member -NotePropertyName GroupNameContent -NotePropertyValue $($GroupNamesContent -join ",") -Force
    $boundary | add-member -NotePropertyName GroupNameSiteOnly -NotePropertyValue $($GroupNamesAssignmentOnly -join ",") -Force
    $boundary | Add-Member -NotePropertyName SiteCodes -NotePropertyValue $($SiteCodes -join ",") -Force
}
write-progress -id 2 -activity "done" -completed


#spilt the boundaries into types
write-host "`tgetting subnets"
$subnets=$boundaries | where {$_.boundarytype -eq 0}
write-host "`tgetting adsite"
$adsites=$boundaries | where {$_.boundarytype -eq 1}
write-host "`tgetting ipv6 prefixes"
$ipv6prefixes=$boundaries | where {$_.boundarytype -eq 2}
write-host "`tgetting ip range"
$iprange=$boundaries | where {$_.boundarytype -eq 3}

#remove ip range
$iprange=$iprange| where {$_.value -ne "165.240.0.1-165.240.255.254"}

#get the ip range information that we can use to compare IP addresses
foreach ($range in $iprange) {
    #the boundary is returned in the format [start ip]-[end ip]
    $BoundaryValue = $range.Value.Split("-")
    $IPStartRange = $BoundaryValue[0]
    $IPEndRange = $BoundaryValue[1]

    #use System.Net.IP.Address to convert the IP address to bytes
    $ParseStartIP = [System.Net.IPAddress]::Parse($IPStartRange).GetAddressBytes()
    [Array]::Reverse($ParseStartIP)
    $ParseStartIP = [System.BitConverter]::ToUInt32($ParseStartIP, 0)
    $ParseEndIP = [System.Net.IPAddress]::Parse($IPEndRange).GetAddressBytes()
    [Array]::Reverse($ParseEndIP)
    $ParseEndIP = [System.BitConverter]::ToUInt32($ParseEndIP, 0)

    #add the values to the hash table
    $range | add-member -NotePropertyName ParseStartIP -NotePropertyValue $ParseStartIP
    $range | add-member -NotePropertyName ParseEndIP -NotePropertyValue $ParseEndIP
}

#initialise values
$alldevices=@()
$count=0

#getting the list of devices from the SMS provider
write-host "getting devices"
$devices = get-wmiobject -Namespace "root\sms\site_$sitecode" -class "SMS_R_System" -ComputerName $ServerName

#if we're listing possible IP ranges, we'll need the network adapter config so we have the subnet mask
If ($listranges) {
    write-host "getting network adapters"
    $networkdevices=get-wmiobject -Namespace "root\sms\site_$sitecode" -class "SMS_G_System_NETWORK_ADAPTER_CONFIGURATION" -ComputerName $ServerName -filter "ipaddress like '%.%' and ipaddress not like '0.0.0.0'"
}

write-host "enumerating $($devices.count)"
foreach ($device in $devices) {
    #provide some progress information
    write-progress -id 1 -activity $device.name -status "$count of $(@($devices).count)" -percentcomplete ($count/@($devices).count*100);$count++
    If ($count % 100 -eq 100) {
        write-host "$count out of $(@($devices).count)"
    }

    #initialise values
    $customdevice=@()
    $CoveredByBoundaryGroup=$false




    #check if the client is covered by an IP range
    If ($iprange) {
        $count2=0
        foreach ($ipaddress2 in $device.ipaddresses) {
            If ($ipaddress2 -like "*.*") {
                #check ip ranges
                If ($iprange) {
                         
                    $ParseIP = [System.Net.IPAddress]::Parse($ipaddress2).GetAddressBytes()
                    [Array]::Reverse($ParseIP)
                    $ParseIP = [System.BitConverter]::ToUInt32($ParseIP, 0)

                    foreach ($range in $iprange) {
                        $CoveredByBoundary=$false
                        If ($ParseIP -ge $range.ParseStartIP -and $ParseIP -le $range.ParseEndIP){
                            If ($range.DPs) {
                                $CoveredByBoundaryGroup=$true
                            }
                            #write-host "$($device.name) $ipaddress" -ForegroundColor Green
                            #write-host $range.value
                            $CoveredByBoundary=$true

                            $Object = New-Object PSObject -Property @{
                                Name=$device.name
                                IP=$ipaddress2
                                Type="IP Range"
                                Value=$($range.Value)
                                BoundaryCount=($range.GroupCount)
                                DPs=$range.DPs
                                SiteCode=$range.SiteCodes
                                GroupNameContent=$range.GroupNameContent
                                GroupNameSiteOnly=$range.GroupNameSiteOnly
                                CoveredByBoundary=$CoveredByBoundary
                                CoveredByBoundaryGroup=$CoveredByBoundaryGroup
                            }
                            $customdevice+=$object
                        }
                    }
                }
            }
            $count2++
        }
    }



    #check if the client is covered by a subnet range
    If ($subnets) {
        #$count3=0
        foreach ($subnet in $device.IPSubnets) {
            $CoveredByBoundary=$false
            $subnetmatch=$subnets | where {$_.value -eq $subnet}
            If ($subnetmatch) {
                If ($subnetmatch.DPs) {
                    $CoveredByBoundaryGroup=$true
                }
                $CoveredByBoundary=$true
            }
            $ipaddress3=$null
            #$ipaddress3=$device.IPAddresses[$count3]

            $Object = New-Object PSObject -Property @{
                Name=$device.name
                IP=$ipaddress3
                Type="Subnet"
                Value=$subnet
                BoundaryCount=($subnetmatch.GroupCount)
                DPs=$subnetmatch.DPs
                SiteCode=$subnetmatch.SiteCodes
                GroupNameContent=$subnetmatch.GroupNameContent
                GroupNameSiteOnly=$subnetmatch.GroupNameSiteOnly
                CoveredByBoundary=$CoveredByBoundary
                CoveredByBoundaryGroup=$false
            }
            $customdevice+=$object
            #$count3++
        }
    }

    #check if the client is covered by an IP v6 prefix
    If ($ipv6prefixes) {
        foreach ($prefix in $device.IPv6Prefixes) {
            $CoveredByBoundary=$false
            $ipv6prefixmatch=$ipv6prefixes | where {$_.value -eq $prefix}
            If ($ipv6prefixmatch) {
                If ($ipv6prefixmatch.DPs) {
                    $CoveredByBoundaryGroup=$true
                }
                $CoveredByBoundary=$true
            }

            $Object = New-Object PSObject -Property @{
                Name=$device.name
                IP=($device.ipv6addresses -join "; ")
                Type="IPv6 Prefix"
                Value=$prefix
                BoundaryCount=($ipv6prefixmatch.GroupCount)
                DPs=$ipv6prefixmatch.DPs
                SiteCode=$ipv6prefixmatch.SiteCodes
                GroupNameContent=$ipv6prefixmatch.GroupNameContent
                GroupNameSiteOnly=$ipv6prefixmatch.GroupNameSiteOnly
                CoveredByBoundary=$CoveredByBoundary
                CoveredByBoundaryGroup=$false
            }
            $customdevice+=$object
        }
    }

    #Check if the client is covered by an AD site boundary
    If ($adsites) {
        $CoveredByBoundary=$false
        $admatch=$adsites | where {$_.value -eq $device.adsitename}
        If ($admatch) {
            If ($admatch.DPs) {
                $CoveredByBoundaryGroup=$true
            }
            $CoveredByBoundary=$true
        }

        $Object = New-Object PSObject -Property @{
            Name=$device.name
            IP=$null
            Type="AD Site"
            Value=$device.adsitename
            BoundaryCount=($admatch.GroupCount)
            DPs=$admatch.DPs
            SiteCode=$admatch.SiteCodes
            GroupNameContent=$admatch.GroupNameContent
            GroupNameSiteOnly=$admatch.GroupNameSiteOnly
            CoveredByBoundary=$CoveredByBoundary
            CoveredByBoundaryGroup=$CoveredByBoundaryGroup
        }

        $customdevice+=$object
    }




        #get possible ip ranges for each clients IP address
    If ($listranges -or -not $CoveredByBoundaryGroup) {
        $networkdeviceresults=$networkdevices | where {$_.resourceid -eq $device.resourceid} 
        foreach ($networkdevice in $networkdeviceresults) {
            $ipaddresses=$networkdevice.ipaddress.split(", ")
            $ipsubnets=$networkdevice.ipsubnet.split(", ")
            $count2=0
            foreach ($ipaddress2 in $ipaddresses) {
                If ($ipaddress2 -like "*.*") {
                    $rangeresult="$ipaddress2 $($ipsubnets[$count2])" | ForEach-Object { Get-ProperCIDR $_ } | ForEach-Object { Get-NetworkInformationFromProperCIDR $_ }
                    $rangecustom="$($rangeresult.hostmin)-$($rangeresult.hostmax)"

                    $Object = New-Object PSObject -Property @{
                        Name=$device.name
                        IP=$ipaddress2
                        Type="Possible IP Range"
                        CIDR="$($rangeresult.NetworkAddress)/$($rangeresult.networklength)"
                        Value=$rangecustom
                        BoundaryCount=$null
                        CoveredByBoundary=$null
                        CoveredByBoundaryGroup=$null
                    }
                    $customdevice+=$object
                }
                $count2++
            }
           
        }
    }




    #if we found a boundary group for the client, we need to set CoveredByBoundaryGroup for each boundary to true
    If ($CoveredByBoundaryGroup) {
        $customdevice | % {$_.CoveredByBoundaryGroup=$true}
    }

    #add the rows to the general table
    $alldevices+=$customdevice

}

#provide a summary and export the results
write-progress -id 1 -Completed -Activity "Done"
$alldevices|export-csv $path -notypeinformation
write-host "exported all device information to $path"
$resultstocheck=$alldevices | where {$_.CoveredByBoundaryGroup -eq $false}
If ($resultstocheck) {
    write-host "There are $($resultstocheck.count) entries for devices that are not covered by a Boundary Group. If some boundaries rely on an IP address, this may include devices discovered from AD or without inventory that do not have a recorded IP address."
    $resultstocheck | select name,ip -Unique | out-gridview -Title "Devices not covered by a boundary group"
} else {
    write-host "All devices are covered by a Boundary Group" -foregroundcolor green
}
