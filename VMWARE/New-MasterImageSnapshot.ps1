<#
	.SYNOPSIS
		A brief description of the New-MasterImageSnapshot.ps1 file.

	.DESCRIPTION
		A description of the file.

	.PARAMETER vCenter
		vCenter FQDN mit dem sich das PowerCLI Modul verbinden soll.

	.PARAMETER ImageVM
		Name der VM die als Masterimage genutzt werden soll.

	.PARAMETER Major
		Handelt es sich um ein Major Version Update dann diesen Switch aktivieren.

	.PARAMETER Minor
		Handelt es sich um ein Minor Update dann diesen Switch aktivieren. Ist kein Switch aktiviert wird von einem Patch oder von Windows Update ausgegangen. Dann wird lediglich die Build Nummer erhöht.

	.PARAMETER Description
		Die Beschreibung die beim Snapshot hinterlegt wird. Sofern keine Beschreibung übergeben wird, wird durch das Skript eine Beschreibung abgefragt.

	.NOTES
	Version
	1.0.0   28.03.2019  TM  Inital Release
#>
param
(
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$vCenter,
    [Parameter(Position = 2)]
    [System.Management.Automation.PSCredential]$Credential,
    [Parameter(Position = 3, Mandatory = $true)]
    [string]$ImageVM,
    [Parameter(Position = 4)]
    [switch]$Major,
    [Parameter(Position = 5)]
    [switch]$Minor,
    [Parameter(Position = 6, Mandatory = $true)]
    [string]$Description
)

begin
{
    $resultMessage = @()

    $resultMessage = $resultMessage | Write-SRLog "Stelle Verbindung mit $vCenter her."
    if ($Credential)
    {
        Connect-VIServer -Server $vCenter -Credential $Credential -Force
    }
    else
    {
        Connect-VIServer -Server $vCenter -Force
    }

    # Die letzten 5 Snapshots auslesen
    $LastSnapShots = Get-Snapshot -VM $ImageVM | Sort-Object Created -Descending | Select-Object -First 5

    $resultMessage = $resultMessage | Write-SRLog "Die letzten 5 Snapshots der Maschine:"
    $resultMessage = $resultMessage | Write-SRLog $($LastSnapShots | Format-Table Name, Description, Created -AutoSize | Out-String)

    Write-Verbose -Message "Die letzten 5 Snapshots der Maschine:"
    Write-Verbose -Message $($LastSnapShots | Format-Table Name, Description, Created -AutoSize | Out-String)

    try
    {
        [System.Version]$OldVersion = $LastSnapShots[0].Name
    }
    catch
    {
        Write-Host "Snapshot falsch bennannt."
    }

    If ($Major)
    {
        [System.Version]$NewVersion = New-Object System.Version($($OldVersion.Major + 1), 0, 0, 0)
    }
    elseif ($Minor)
    {
        [System.Version]$NewVersion = New-Object System.Version($OldVersion.Major, $($OldVersion.Minor + 1), 0, 0)
    }
    else
    {
        [System.Version]$NewVersion = New-Object System.Version($OldVersion.Major, $OldVersion.Minor, $($OldVersion.Build + 1), 0)
    }

    $resultMessage = $resultMessage | Write-SRLog "Der neue Snapshot erhält die Versionsummer: $NewVersion"

    $resultMessage = $resultMessage | Write-SRLog "Erzeuge Snapshot: `nVM: $ImageVM`nName: $NewVersion`nBeschreibung: $Description"
    $NewSnapshot = New-Snapshot -VM $ImageVM -Name $NewVersion -Description $Description

}

process
{

}

end
{
    if ($SRXEnv)
    {
        $SRXEnv.ResultMessage = $resultMessage
    }
}