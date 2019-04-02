<#
	.SYNOPSIS
		Sucht über die IMC Rest API nach dem Port und dem Switch an dem ein IP Device angeschlossen ist.

	.DESCRIPTION
		Sucht über die IMC REST API nach dem Switch und dem Interface an das die MAC Adresse oder die IP angebunden ist. Man muss entweder die MAC Adresse oder die IP des Terminals angeben.

		In der Regel ist es jedoch erfolgversprechender wenn man die MAC Adresse angibt.

    .PARAMETER ImcHost
        FQDN oder Hostname des IMC Hosts

    .PARAMETER ImcProt
        Protokoll welches für die Kommunikation genutzt wird. HTTP oder HTTTPS (empfohlen)

    .PARAMETER ImcPort
        Port unter dem der IMC läuft.

	.PARAMETER TerminalMAC
		MAC Adresse des gesuchten PCs oder Netzwerkteilnehmer

	.PARAMETER TerminalIP
		IP Adresse des gesuchten PCs oder Netzwerkteilnehmer

	.PARAMETER Size
		Anzahl wie viele Datensätze abgerufen werden. Standardmäßig wird nur der letzte Datensatz abgerufen.

	.PARAMETER ImcUser
		Benutzername mit dem sich das Skript an der IMC Rest API anmeldet.

	.PARAMETER ImcPassword
		Wird das Passwort mit angegeben kann mit einem zusätzlichen Parameter eine Passwortdatei erzeugt werden. Diese kann nur mit dem aktuellen User auf dem aktuellen PC wieder in der Powershell entschlüsselt werden.

	.PARAMETER CreatePasswordFile
		Erzeugt eine Credential File sofern ein Passwort mit angegeben worden ist. Anschließend kann das Skript auch unattended unter dem aktuellen Benutzer ausgeführt werden.

	.PARAMETER AcceptSelfSignedCertificate
		A description of the AcceptSelfSignedCertificate parameter.

	.PARAMETER AcceptSelfSignedCertificates
		Sofern man HTTPs nutzt und nur ein Selbst-Signiertes Zertifkat hat, beendet sich das Skript mit einem Fehler. In diesem Fall kann man hierüber auch Selbst-Signierte Zertifikate akzeptieren.


	.NOTES
    Version
    1.0.0   28.08.2018  TM  Inital Release
#>
function Get-ImcSwitchPort
{
    [CmdletBinding(DefaultParameterSetName = 'MAC')]
    [OutputType([pscustomobject])]
    param
    (
        [System.String]$ImcHost,
        [ValidateSet('https', 'http')]
        [System.String]$ImcProt = "https",
        [System.int]$ImcPort = "8443",
        [Parameter(ParameterSetName = 'MAC',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'MAC Adresse des gesuchten PCs oder Netzwerkteilnehmer. Format: XX:XX:XX:XX:XX:XX')]
        [Alias('PrimaryMAC', 'MacAddress')]
        [string]$TerminalMAC,
        [Parameter(ParameterSetName = 'IP',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'IP Adresse des gesuchten PCs oder Netzwerkteilnehmer. Format: 10.11.8.1 oder 192.168.172.5')]
        [Alias('PrimaryIP')]
        [string]$TerminalIP,
        [Parameter(Position = 2)]
        [string]$Size = "1",
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credentials,
        [Parameter(Position = 6)]
        [bool]$AcceptSelfSignedCertificate = $true
    )

    BEGIN
    {
        #region Konfiguration

        #IMC Serverkonfiguration
        If (!($ImcHost))
        {
            [string]$ImcHost = Get-PSFConfigValue -FullName "MyFunctions.Imc.Fqdn"
        }
        $Result = @()
        #endregion

        #region Authentifizierung

        If (!($Credentials))
        {
            $Credentials = Get-PSFConfigValue -FullName "Schriesheim-IT.CurentCredentials"
            If (!($Credentials))
            {
                $Credentials = Get-Credential -UserName $Env:USERNAME -Message "Bitte Passwort eingeben für den REST API Zugriff"
                Set-PSFConfig -FullName "Schriesheim-IT.CurentCredentials" -Value $Credentials
            }
        }

        #endregion


        #IMC Basis URL
        $ImcApiBaseUrl = $ImcProt + "://" + $ImcHost + ":" + $ImcPort + "/imcrs"
        Write-Verbose -Message "Erzeuge IMC Basis URL: $ImcApiBaseUrl"

        #Header für Response in JSON
        $headers = @{
            "accept" = "application/json"
        }

        if ($AcceptSelfSignedCertificate)
        {
            Write-Verbose -Message "Setze Cerificate Policy auf 'TrustAllCerts'"
            add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
            return true;
        }
 }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

    }
    PROCESS
    {

        #region Check Parameter Set
        # Prüft welcher Parameter gesucht wird
        switch ($PsCmdlet.ParameterSetName)
        {
            'MAC'
            {
                $ImcApiFullUrl = "$ImcApiBaseUrl/res/access/historyAccessLog?terminalMac=$TerminalMAC&size=$Size"
            }
            'IP'
            {
                $ImcApiFullUrl = "$ImcApiBaseUrl/res/access/historyAccessLog?terminalIp=$TerminalIP&size=$Size"
            }
        }
        #endregion

        # Try one or more commands
        try
        {
            #Abruf der History Access Log Daten
            Write-Verbose -Message $ImcApiFullUrl
            $Result = Invoke-RestMethod -Uri $ImcApiFullUrl -Credential $Credentials -Headers $headers
        }
        # Catch specific types of exceptions thrown by one of those commands
        catch [System.Net.WebException]
        {
            <#
            $ErrorMessage = @"

		Der Webrequest ist fehlgeschlagen. Bitte prüfen Sie das eingegebene oder hinterlegte Passwort.
		Sollten Sie ein Selbst-Signiertes Passwort nutzen prüfen sie ob sie den Parameter -AcceppSelfSignedCertificate gesetzt haben
"@
#>

            Write-Error -Message $_
            Break
        }
        # Catch all other exceptions thrown by one of those commands
        catch
        {
            Write-Error $Error
        }

        If ($Result.HistoryAccessLog)
        {

            foreach ($Item in $Result.HistoryAccessLog)
            {
                $Terminal = [PSCustomObject]@{
                    Mac       = $Item.TerminalMAC
                    IP        = $Item.TerminalIP
                    Switch    = $Item.deviceSymbolName
                    Interface = $Item.ifIndex
                    VLAN      = $Item.vlanId
                    Login     = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Item.upLineTime))
                    Logout    = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Item.downLineTime))
                }
                if ($SRXEnv)
                {
                    $Result += $Terminal
                }
                else
                {
                    $Terminal
                }
            }

        }
        else
        {
            $Terminal = [PSCustomObject]@{
                Mac       = $TerminalMAC
                Switch    = "Nicht gefunden"
                Interface = "Nicht gefunden"
                VLAN      = ""
            }
            if ($SRXEnv)
            {
                $Result += $Terminal
            }
            else
            {
                $Terminal
            }
        }
    }
    END
    {
        [System.Net.ServicePointManager]::CertificatePolicy = $null
        if ($SRXEnv)
        {
            $SRXEnv.ResultMessage = $Result
        }
    }
}