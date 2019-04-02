<#
	.SYNOPSIS
		A brief description of the Update-XenDesktopMasterImage.ps1 file.

	.DESCRIPTION
		A description of the file.

	.PARAMETER adminAddress
		A description of the adminAddress parameter.

	.PARAMETER masterImage
		A description of the masterImage parameter.

	.PARAMETER machineCatalogName
		A description of the machineCatalogName parameter.

	.PARAMETER snapshotName
		A description of the snapshotName parameter.

	.PARAMETER storageResource
		A description of the storageResource parameter.

	.PARAMETER hostResource
		A description of the hostResource parameter.

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
		Created on:   	29.06.2018 12:01
		Created by:   	s2041
		Organization:
		Filename:
		===========================================================================
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string]$adminAddress = '',
    [Parameter(Mandatory = $true)]
    [string]$masterImage = '',
    [Parameter(Mandatory = $true)]
    [string]$machineCatalogName = '',
    [Parameter()]
    [string]$snapshotName,
    [Parameter(Mandatory = $true)]
    [string]$storageResource = '',
    [Parameter(Mandatory = $true)]
    [string]$hostResource = ''
)

begin
{
    $resultMessage = @()
}

process
{

    # Load the Citrix PowerShell modules
    Write-Verbose -Message "Loading Citrix XenDesktop modules."
    Add-PSSnapin Citrix*

    #Set Authentification to On Premise Installation
    Set-XDCredentials -ProfileType OnPrem

    # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
    Write-Verbose -Message "Getting the snapshot details for the catalog: $machineCatalogName"

    $masterImage = "$masterImage.vm"
    $VM = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits\$storageResource" | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like $masterImage }
    # Get the snapshot details. This code will grab a specific snapshot, although you could grab the last in the list assuming it's the latest.
    $VMSnapshots = Get-ChildItem -AdminAddress $adminAddress $VM.FullPath -Recurse -Include *.snapshot

    #region Check Parameter Set
    # Prüft welcher Parameter gesucht wird
    If ($snapshotName)
    {
        $TargetSnapshot = $VMSnapshots | Where-Object { $_.FullName -eq "$snapshotName.snapshot" }
    }
    else
    {
        $TargetSnapshot = $VMSnapshots | Select-Object -Last 1
    }
    #endregion

    # Publish the image update to the machine catalog
    # http://support.citrix.com/proddocs/topic/citrix-machinecreation-admin-v2-xd75/publish-provmastervmimage-xd75.html
    $PubTask = Publish-ProvMasterVmImage -AdminAddress $adminAddress -MasterImageVM $TargetSnapshot.FullPath -ProvisioningSchemeName $machineCatalogName -RunAsynchronously
    $provTask = Get-ProvTask -AdminAddress $adminAddress -TaskId $PubTask

    # Track progress of the image update
    $resultMessage = $resultMessage | Write-SRLog "Tracking progress of the machine creation task."
    $totalPercent = 0
    While ($provTask.Active -eq $True)
    {
        Try
        {
            $totalPercent = If ($provTask.TaskProgress) { $provTask.TaskProgress }
            Else { 0 }
        }
        Catch
        {
            Write-Error "Fehler: Fortschritt kann nicht angezeigt werden!"
        }
        Write-Progress -Activity "Provisioning image update" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
        Start-Sleep 15
        $provTask = Get-ProvTask -AdminAddress $adminAddress -TaskId $PubTask
    }
}

end
{
    if ($SRXEnv)
    {
        $SRXEnv.ResultMessage = $resultMessage
    }
}
# Start the desktop reboot cycle to get the update to the actual desktops
# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/start-brokerrebootcycle-xd75.html
# Start-BrokerRebootCycle -AdminAddress $adminAddress -InputObject @($machineCatalogName) -RebootDuration 60 -WarningDuration 15 -WarningMessage $messageDetail -WarningTitle $messageTitle