<#
.SYNOPSIS
Imports the Yodel module into the current session.

.DESCRIPTION
The `Import-Yodel function imports the Yodel module into the current session. If the module is already loaded, it is removed, then reloaded.

.EXAMPLE
.\Import-Yodel.ps1

Demonstrates how to use this script to import the Yodel module  into the current PowerShell session.
#>
[CmdletBinding()]
param(
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

$originalVerbosePref = $Global:VerbosePreference
$originalWhatIfPref = $Global:WhatIfPreference

$Global:VerbosePreference = $VerbosePreference = 'SilentlyContinue'
$Global:WhatIfPreference = $WhatIfPreference = $false

try
{
    if( (Get-Module -Name 'Yodel') )
    {
        Remove-Module -Name 'Yodel' -Force
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Yodel.psd1' -Resolve)
}
finally
{
    $Global:VerbosePreference = $originalVerbosePref
    $Global:WhatIfPreference = $originalWhatIfPref
}
