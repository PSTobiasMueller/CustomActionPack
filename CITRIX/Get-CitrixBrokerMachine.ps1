<#
    .SYNOPSIS
        A brief description of the Update-XenDesktopMasterImage.ps1 file.

    .DESCRIPTION
        A description of the file.

    .PARAMETER adminAddress
        Address of the Citrix XenDesktop Delivery Controller

    .PARAMETER machineCatalogName
        Filter for the Machine Catalog to retrieve

    .PARAMETER ImageOutOfDate
        Only show Broker Machines with ImageOutOfDate

    .PARAMETER SummaryState
        Show only Broker Machine in the assigned Status

    .NOTES
        Version
        1.0.0   28.03.2019  TM  Inital Release
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    [string]
    $adminAddress = '',
    [string]
    $machineCatalogName = '',
    [switch]
    $ImageOutOfDate,
    [ValidateSet('Off', 'Unregistered', 'Available', 'Disconnected', 'InUse', IgnoreCase = $true)]
    [string]
    $SummaryState
)

begin
{
    $resultMessage = @()

    # Load the Citrix PowerShell modules
    Write-Verbose -Message "Loading Citrix XenDesktop modules."
    Add-PSSnapin Citrix*

    #Set Authentification to On Premise Installation
    Set-XDCredentials -ProfileType OnPrem

    if ([System.String]::IsNullOrEmpty($machineCatalogName))
    {
        $machineCatalogName = "*"
    }

    #Retrieves the Broker Machines
    $paramGetBrokerMachine = [hashtable]@{
        AdminAddress = $adminAddress
        CatalogName  = $machineCatalogName
    }

    If ($ImageOutOfDate)
    {
        $paramGetBrokerMachine += [hashtable] @{
            ImageOutOfDate = [bool]::Parse($ImageOutOfDate)
        }
    }

    If ($SummaryState)
    {
        $paramGetBrokerMachine += [hashtable] @{
            SummaryState = $SummaryState
        }
    }
}

process
{

    # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
    Write-Verbose -Message "Getting the Broker Machines for the catalog: $machineCatalogName"

    $Machines = Get-BrokerMachine @paramGetBrokerMachine | Sort-Object -Property HostedMachineName | Select-Object CatalogName, HostedMachineName, AssociatedUserFullNames, AssociatedUserNames, PowerState, RegistrationState, ImageOutOfDate
}

end
{
    if ($SRXEnv)
    {
        $SRXEnv.ResultMessage = $Machines | Format-Table -AutoSize
    }
    else
    {
        $Machines | Format-Table -AutoSize
    }
}
# Start the desktop reboot cycle to get the update to the actual desktops
# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/start-brokerrebootcycle-xd75.html
# Start-BrokerRebootCycle -AdminAddress $adminAddress -InputObject @($machineCatalogName) -RebootDuration 60 -WarningDuration 15 -WarningMessage $messageDetail -WarningTitle $messageTitle