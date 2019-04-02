
#Requires -Version 4.0

<#
.SYNOPSIS
    Installs the specified Moduls in Required Modules

.DESCRIPTION

.NOTES
    Author: Tobias Müller
    Created: 21.12.2018

.COMPONENT

.LINK

.Parameter LocalRepositoryName
    Name of the Local Repository

.Parameter LocalRepositoryPath
    UNC Path to the Local Repository

.Parameter RequiredModules
    Specifies the Modules to Install

#>

[CmdLetBinding()]
param(
    [Parameter(Mandatory = $False)]
    [System.String]$LocalRepositoryName,
    [Parameter(Mandatory = $False)]
    [System.String]$LocalRepositoryPath,
    [Parameter(Mandatory = $True)]
    [System.String[]]$RequiredModules
)

$resultMessage = @()

Import-Module PowerShellGet

$resultMessage = $resultMessage | Write-SRLog "Prüfe auf Repository $LocalRepositoryName"
If (!(Get-PSRepository -Name $LocalRepositoryName -ErrorAction SilentlyContinue))
{
    $resultMessage = $resultMessage | Write-SRLog "Registriere Repository $LocalRepositoryName ."
    $Params = @{
        Name                  = $LocalRepositoryName
        SourceLocation        = $LocalRepositoryPathRepository
        InstallationPolicy    = "Trusted"
        PublishLocation       = $LocalRepositoryPath
        ScriptSourceLocation  = $LocalRepositoryPath
        ScriptPublishLocation = $LocalRepositoryPath
    }

    Register-PSRepository @Params
}
else
{
    $resultMessage = $resultMessage | Write-SRLog "Repository $LocalRepositoryName bereits vorhanden."
}

foreach ($module in $requiredModules)
{
    $resultMessage = $resultMessage | Write-SRLog "$module : Prüfe lokale Installation von Modul $module."
    $installedModule = Get-Module -Name $module -ListAvailable
    $repositoryModule = Find-Module $module -Repository $LocalRepositoryName
    If ($installedModule)
    {
        $resultMessage = $resultMessage | Write-SRLog "$module : Lokale Installation mit Version $($installedModule.Version) gefunden."
        if ($installedModule.Version -lt $repositoryModule.Version)
        {
            $resultMessage = $resultMessage | Write-SRLog "$module : Neuere Version auf $LocalRepositoryName gefunden."
            $resultMessage = $resultMessage | Write-SRLog "$module : Aktualisiere $Module auf Version $($repositoryModule.Version) ."
            Remove-Module -Name $module -Force -ErrorAction SilentlyContinue
            Uninstall-Module -Name $module -Force
            Install-Module $module -Repository $LocalRepositoryName -Scope AllUsers
            If ($installedModule.Version -eq $repositoryModule.Version)
            {
                $resultMessage = $resultMessage | Write-SRLog "$module : Modul erfolgreich aktualisiert."
            }
            else
            {
                $resultMessage = $resultMessage | Write-SRLog "$module : Aktualisierung fehlgeschlagen. Bitte Modul manuell installieren."
            }
        }
        else
        {
            $resultMessage = $resultMessage | Write-SRLog "$module : Aktuellste Version ist installiert."
        }
    }
    else
    {
        if ($repositoryModule)
        {
            $resultMessage = $resultMessage | Write-SRLog "$module : Modul in Repository $LocalRepositoryName mit Version $($repositoryModule.Version) gefunden."
        }
        $resultMessage = $resultMessage | Write-SRLog "$module : Installiere $Module in Version $($repositoryModule.Version)"
        Install-Module $module -Repository $LocalRepositoryName -Scope AllUsers
        $installedModule = Get-Module -Name $module -ListAvailable
        If ($installedModule.Version -eq $repositoryModule.Version)
        {
            $resultMessage = $resultMessage | Write-SRLog "$module : Modul erfolgreich installiert."
        }
        else
        {
            $resultMessage = $resultMessage | Write-SRLog "$module : Installation fehlgeschlagen. Bitte Modul manuell installieren."
        }
    }
}

if ($SRXEnv)
{
    $SRXEnv.ResultMessage = $resultMessage
}
else
{
    Write-Output $resultMessage
}