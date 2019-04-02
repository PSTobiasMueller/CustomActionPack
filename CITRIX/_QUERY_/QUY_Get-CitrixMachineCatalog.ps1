#Requires -Version 4.0

<#
.SYNOPSIS
    Retrieves names of the available Machine Catalogs

.DESCRIPTION

.NOTES

.COMPONENT
    Citrix Powershell SDK

.Parameter AdminAddress
    Specifies the IP address or the DNS name of the Delivery Controller

#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$AdminAddress
)

# Load the Citrix PowerShell modules
Write-Verbose "Loading Citrix XenDesktop modules."
Add-PSSnapin Citrix*

#Set Authentification to On Premise Installation
Set-XDCredentials -ProfileType OnPrem

try
{

    if ($SRXEnv)
    {
        $SRXEnv.ResultList = @()
        $SRXEnv.ResultList2 = @()
    }
    $BrokerCatalog = Get-BrokerCatalog -AdminAddress $adminAddress | select Name, Description

    foreach ($item in $BrokerCatalog)
    {
        if ($SRXEnv)
        {
            $SRXEnv.ResultList += $item.Name
            $SRXEnv.ResultList2 += $item.Name
        }
        else
        {
            Write-Output $item
        }
    }
}
catch
{
    throw
}