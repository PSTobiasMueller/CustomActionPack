function  Publish-PhoneList
{
    <#
.Synopsis
Publishs the Phone list received from Get-iDoitPhoneList on the Intranet Server

.DESCRIPTION
Publishs the Phone list received from Get-iDoitPhoneList on the Intranet Server

.Parameter Computername
Hostname/FQDN/IP of the Intranet Server

.Parameter KeyFile
File to the SSH Private Key

.PARAMETER Credentials
Password for the SSH Private Key

.PARAMETER RemotePath
Path on the Server

.Parameter LocalPath
UNC Path on the File Server

.NOTES
Version
1.0.0   21.08.2018  TM  Inital Release
1.1.0   09.01.2019  TM  Added ScriptRunner Support and Help
#>
    [CmdletBinding()]
    Param
    (
        [System.String]$Computername,
        [System.IO.FileInfo]$KeyFile,
        [System.Management.Automation.PSCredential]$Credential,
        [System.String]$RemotePath,
        [System.IO.FileInfo]$LocalPath
    )

    begin
    {
        If (!($RemotePath))
        {
            $RemotePath = Get-PSFConfigValue -FullName "myfunctions.phonelist.remotepath"
            Write-PSFMessage -Level SomewhatVerbose -Message "No RemotePath found. Load Config Value: $RemotePath"
        }

        If (!($Computername))
        {
            $Computername = Get-PSFConfigValue -FullName "myfunctions.phonelist.remoteserver"
            Write-PSFMessage -Level SomewhatVerbose -Message "No Computername found. Load Config Value: $Computername"
        }

        If (!($LocalPath))
        {
            $LocalPath = Get-PSFConfigValue -FullName "myfunctions.phonelist.exportpath"
            Write-PSFMessage -Level SomewhatVerbose -Message "No LocalPath found. Load Config Value: $LocalPath"
        }

        If (!($KeyFile))
        {
            $KeyFile = Get-PSFConfigValue -FullName "myfunctions.phonelist.keyfile"
            Write-PSFMessage -Level SomewhatVerbose -Message "No KeyFile found. Load Config Value: $KeyFile"
        }

        If (!($Credential))
        {
            Write-PSFMessage -Level SomewhatVerbose -Message "No Credential found. Creating Credentials!"
            $Credential = Get-Credential -UserName $(Get-PSFConfigValue -FullName "myfunctions.phonelist.sshuser") -Message "Bitte Passwort für SSH Key eingeben:"
        }

        $defaultList = "idoit_telefonliste_default.csv"
        $widgetList = "idoit_telefonliste_widget.csv"

        $defaultListPath = Join-Path $LocalPath -ChildPath  $defaultList
        $widgetListPath = Join-Path $LocalPath -ChildPath  $widgetList
    }

    process
    {
        $Params = @{
            ComputerName = $Computername
            Credential   = $Credential
            KeyFile      = $KeyFile
            RemotePath   = $RemotePath
            LocalFile    = ""
            AcceptKey    = $True
        }

        if (Test-Path -Path $defaultListPath)
        {
            $Params.LocalFile = $defaultListPath
            Set-scpfile @Params
        }

        if (Test-Path -Path $widgetListPath)
        {
            $Params.LocalFile = $widgetListPath
            Set-scpfile @Params
        }
    }
}