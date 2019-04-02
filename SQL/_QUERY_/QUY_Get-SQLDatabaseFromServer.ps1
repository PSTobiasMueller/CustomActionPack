#Requires -Version 4.0
#Requires -Module "dbatools"

<#
.SYNOPSIS
    Gets the SQL Databases of the disks

.DESCRIPTION
    Gets the SQL Databases of the disks

.NOTES
    Author: Tobias Müller
    Created: 21.12.2018

.COMPONENT
    dbaTools

.LINK


.Parameter SQLInstance
    Specifies the SQL Server Instance

.Parameter ExcludeSystemDatabses
    Excludes the System Databses in the Result
#>

[CmdLetBinding()]
Param(
    [string]$SQLInstance,
    [Switch]$ExcludeSystemDatabses
)

try
{
    If (Test-DbaConnection -SqlInstance $SQLInstance)
    {
        $Databases = Get-DbaDatabase -SqlInstance $SQLInstance -ExcludeAllSystemDb:$ExcludeSystemDatabses | Select-Object $name
        if ($Databases.Count -gt 0)
        {
            if ($SRXEnv)
            {
                $SRXEnv.ResultList = $Databases
                $SRXEnv.ResultList2 = $($Databases -replace "\[", "") -replace "\]", ""
            }
            else
            {
                $Databases
            }
        }
    }
    else
    {
        $SRXEnv.ResultMessage = "Host is not Online"
    }
}
catch
{
    throw
}
finally
{
}