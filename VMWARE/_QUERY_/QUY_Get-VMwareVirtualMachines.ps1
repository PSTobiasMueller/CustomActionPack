#Requires -Version 4.0
# Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    Retrieves the virtual machines on a vCenter Server system

.DESCRIPTION

.NOTES
    This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner.
    The customer or user is authorized to copy the script from the repository and use them in ScriptRunner.
    The terms of use for ScriptRunner do not apply to this script. In particular, AppSphere AG assumes no liability for the function,
    the use and the consequences of the use of this freely available script.
    PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of AppSphere AG.
    © AppSphere AG

.COMPONENT
    Requires Module VMware.PowerCLI

.LINK
    https://github.com/scriptrunner/ActionPacks/tree/master/VMware/_QUERY_

.Parameter VIServer
    Specifies the IP address or the DNS name of the vSphere server to which you want to connect

.Parameter VICredential
    Specifies a PSCredential object that contains credentials for authenticating with the server
#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$VIServer,
    [Parameter(Mandatory = $true)]
    [pscredential]$VICredential
)

Import-Module VMware.PowerCLI

try
{
    $Script:vmServer = Connect-VIServer -Server $VIServer -Credential $VICredential -ErrorAction Stop

    if ($SRXEnv)
    {
        $SRXEnv.ResultList = @()
        $SRXEnv.ResultList2 = @()
    }
    $Script:machines = Get-VM -Server $Script:vmServer -ErrorAction Stop | Sort-Object -Property Name | Select-Object Id, Name, Notes

    foreach ($item in $Script:machines)
    {
        if ($SRXEnv)
        {
            $SRXEnv.ResultList += $item.Name
            $SRXEnv.ResultList2 += "$($item.Name) - $($item.Notes)" # Display
        }
        else
        {
            Write-Output "$($item.Name) - $($item.Notes)"
        }
    }
}
catch
{
    throw
}
finally
{
    if ($null -ne $Script:vmServer)
    {
        Disconnect-VIServer -Server $Script:vmServer -Force -Confirm:$false
    }
}