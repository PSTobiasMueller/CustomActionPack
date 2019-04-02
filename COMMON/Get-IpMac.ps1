function Get-IPMAC
{
    <#
        .Synopsis
        Function to retrieve IP & MAC Address of a Machine.
        .DESCRIPTION
        This Function will retrieve IP & MAC Address of local and remote machines.
        .EXAMPLE
        PS>Get-ipmac -ComputerName viveklap
        Getting IP And Mac details:
        --------------------------

        Machine Name : TESTPC
        IP Address : 192.168.1.103
        MAC Address: 48:D2:24:9F:8F:92
        .INPUTS
        System.String[]
        .NOTES
        Author - Vivek RR
        Adapted logic from the below blog post
        "http://blogs.technet.com/b/heyscriptingguy/archive/2009/02/26/how-do-i-query-and-retrieve-dns-information.aspx"
#>

    Param
    (
        #Specify the Device names
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [string[]]$ComputerName
    )

    begin
    {
        $Result = @()
    }
    process
    {
        foreach ($computer in $ComputerName )
        {
            $computerObject = [PSCustomObject]@{
                ComputerName = $computer
                IpAddress    = "Unknown"
                MacAddress   = "Unknown"
                Connection   = "Unknown"
            }

            if (!(Test-Connection -Cn $computer -quiet -Count 1))
            {
                $computerObject.Connection = "Offline"
            }
            else
            {
                $computerObject.Connection = "Online"
                $computerObject.IpAddress = ([System.Net.Dns]::GetHostByName($computerObject.ComputerName).AddressList[0]).IpAddressToString
                $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computerObject.ComputerName
                $computerObject.MacAddress = ($networkAdapters | Where-Object { $_.IpAddress -eq $computerObject.IpAddress}).MACAddress
            }
            if ($SRXEnv)
            {
                $Result += $computerObject
            }
            else
            {
                $computerObject
            }
        }
    }
    end
    {
        if ($SRXEnv)
        {
            $SRXEnv.ResultMessage = $Result
        }
    }
}