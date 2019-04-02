Function Get-iDoitPhoneList
{
    <#
.Synopsis
Retrieves the iDoit Report 50 and Converts it to CSV for Phone and Widget List

.DESCRIPTION
Retrieves the iDoit Report 50 and Converts it to CSV for Phone and Widget List

.Parameter Computername
Hostname/FQDN/IP of the i-doit Server.

.Parameter ApiKey
API key used for the Authentification

.PARAMETER Credentials
Addiditional Credentials for Authentification

.PARAMETER ExportPath
Export Folder to Save the CSV Files

.Parameter OpenFile
If used the CSV Files will open by the Script in the Systems .CSV Default Application

.NOTES
Version
1.0.0   09.01.2019  TM  Inital Release
#>
    [CmdletBinding()]
    param (
        [System.String]$ComputerName,
        [System.String]$ApiKey,
        [PSCredential]$Credential,
        [System.IO.DirectoryInfo]$ExportPath,
        [Switch]$OpenFile
    )

    begin
    {
        $resultMessage = @()

        If (!(Get-iDoitInfo))
        {
            if (!($ComputerName))
            {
                $ComputerName = Get-PSFConfigValue -FullName "psidoit.idoit.server"
            }
            if (!($ApiKey))
            {
                $ApiKey = Get-PSFConfigValue -FullName  "psidoit.idoit.apikey"
            }
            $resultMessage = $resultMessage | Write-SRLog "Initalisiere iDoit Verbindung"
            if (!($Credential))
            {
                $User = Get-PSFConfigValue -FullName  "psidoit.idoit.user"
                Initialize-idoit -Server $ComputerName -Credentials $Credential -ApiKey $ApiKey
            }
            else
            {
                Initialize-idoit -Server $ComputerName -ApiKey $ApiKey
            }
            $iDoitInfo = Get-iDoitInfo
            If ($iDoitInfo)
            {
                $resultMessage = $resultMessage | Write-SRLog "Verbindung mit iDoit Version $($iDoitInfo.Version) hergestellt."
            }
            else
            {
                $resultMessage = $resultMessage | Write-SRLog "Verbindung mit iDoit fehlgeschlagen."
                Throw "Verbindung fehlgeschlagen"
            }
        }
        if (!($ExportPath))
        {
            $ExportPath = Get-PSFConfigValue -FullName "myfunctions.phonelist.exportpath"
        }

        function Export-CSVWithResult
        {
            param(
                [System.String]$FileName,
                [Parameter(
                    ValueFromPipeline = $true)]
                [PSCustomObject]$InputObject
            )

            begin
            {
                $fullPath = Join-Path $ExportPath -ChildPath $FileName
                If (Test-Path $fullPath)
                {
                    Remove-item -Path $fullPath -Force
                }
                $Export = @()
            }

            process
            {
                $Export += $InputObject
            }

            end
            {
                $Export | Export-Csv -Path $fullPath -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force
                Test-Path -Path $fullPath
            }

        }
    }

    process
    {
        $resultMessage = $resultMessage | Write-SRLog "Lade iDoit Report Nr. 50"
        $longList = Get-iDoitReport -ReportID 50
        $widgetList = $longList | Select-Object -Property Nachname, Vorname, Telefon, Handy, Abteilung, Einrichtung

        $resultMessage = $resultMessage | Write-SRLog "Exportiere Telefonliste"
        $Return = $longList | Export-CSVWithResult -FileName "idoit_telefonliste_default.csv"
        $resultMessage = $resultMessage | Write-SRLog "Ergebnis Telefonliste: $Return"
        $resultMessage = $resultMessage | Write-SRLog "Exportiere Widgetliste"
        $Return = $widgetList | Export-CSVWithResult -FileName "idoit_telefonliste_widget.csv"
        $resultMessage = $resultMessage | Write-SRLog "Ergebnis Widgetliste: $Return"


        if ($OpenFile)
        {
            Start-Process -FilePath $localPathDefaultList
        }
    }

    end
    {
        if ($SRXEnv)
        {
            $SRXEnv.ResultMessage = $resultMessage
        }
        else
        {
            Write-Output $resultMessage
        }

    }
}