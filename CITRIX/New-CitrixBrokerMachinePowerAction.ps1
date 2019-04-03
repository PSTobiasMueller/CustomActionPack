<#
    .SYNOPSIS
        Assigns the powerAction to a specific set of Broker Machines

    .DESCRIPTION
        Assigns the powerAction to a specific set of Broker Machines

    .PARAMETER adminAddress
        Address of the Citrix XenDesktop Delivery Controller

    .PARAMETER powerAction
        Action to Apply to the Broker Machine

    .PARAMETER machineCatalogName
        Specifies the machineCatalogName of the Broker Machine you want to set the powerAction

    .PARAMETER imageOutOfDate
        Only Broker Machines with imageOutOfDate get the powerAction

    .PARAMETER summaryState
        Specifies the summeryState of the Broker Machine you want to set the powerAction

    .PARAMETER SRWhatIf
        Test-Modus, you'll only see what machines will be assigned the powerAction but the
        powerAction will not be applied.


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
    [Parameter(Mandatory = $true)]
    [ValidateSet('Reset', 'Restart', 'Resume', 'Shutdown', 'Suspend', 'TurnOff', 'TurnOn', IgnoreCase = $true)]
    [string]$powerAction,
    [string]
    $machineCatalogName = '',
    [switch]
    $ImageOutOfDate,
    [ValidateSet('Off', 'registered', 'Available', 'Disconnected', 'InUse', IgnoreCase = $true)]
    [string]
    $SummaryState,
    [switch]$SRWhatIf
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

    If ($PSBoundParameters.ContainsKey($ImageOutOfDate))
    {
        $paramGetBrokerMachine.Add('ImageOutOfDate', [bool]::Parse($ImageOutOfDate))
    }

    If ($PSBoundParameters.ContainsKey($SummaryState))
    {
        $paramGetBrokerMachine.Add('SummaryState', $SummaryState)
    }
}

process
{
    # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
    Write-Verbose -Message "Getting the Broker Machines for the catalog: $machineCatalogName"

    if ($PSBoundParameters.ContainsKey('SRWhatIf'))
    {
        Write-Verbose -Message "The powerAction $poweraction would be applied to the those Machines:"
        $resultMessage += "WHAT IF: The powerAction $poweraction would be applied to the those Machines:"
        $Machines = Get-BrokerMachine @paramGetBrokerMachine
    }
    else
    {
        Write-Verbose -Message "The powerAction $poweraction was applied to the those Machines:"
        $resultMessage += "The powerAction $poweraction was applied to the those Machines:"
        $Machines = Get-BrokerMachine @paramGetBrokerMachine | New-BrokerHostingPowerAction  -Action $powerAction -AdminAddress "b1shba-xen.b1shba.intern:80"
    }

}

end
{
    if ($SRXEnv)
    {
        $resultMessage += $Machines | Format-Table -AutoSize -Property HostedMachineName, AssociatedUserFullNames, SummaryState
        $SRXEnv.ResultMessage = $resultMessage
    }
    else
    {
        $Machines | Format-Table -AutoSize
    }
}
# Start the desktop reboot cycle to get the update to the actual desktops
# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/start-brokerrebootcycle-xd75.html
# Start-BrokerRebootCycle -AdminAddress $adminAddress -InputObject @($machineCatalogName) -RebootDuration 60 -WarningDuration 15 -WarningMessage $messageDetail -WarningTitle $messageTitle