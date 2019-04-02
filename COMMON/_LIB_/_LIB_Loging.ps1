Function Write-SRLog
{
    <#
.SYNOPSIS
    Write a Log Entry to the Result Message

.DESCRIPTION
    Write a Log Entry to the Result Message

.NOTES
    Author: Tobias Müller
    Created: 21.12.2018

.COMPONENT

.LINK

.Parameter Message
    Specifies the Log Message

.Parameter NoDateTime
    No DateTime in Front of the Entry
#>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,
        [Switch]$NoDateTime,
        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [System.String[]]$LogArray
    )

    begin
    {
        $TempLogArray = @()
    }
    process
    {
        ForEach ($Log in $LogArray)
        {
            $TempLogArray += $Log
        }
    }
    end
    {
        if ($NoDateTime)
        {
            $TempLogArray += $Message
        }
        else
        {
            $DateString = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $TempLogArray += "[$DateString] $Message"
        }
        $TempLogArray
    }
}