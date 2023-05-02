
function Test-YMsSqlSchema
{
    <#
    .SYNOPSIS
    Checks if a schema exists in Microsoft SQL Server.

    .DESCRIPTION
    The `Test-YMsSqlSchema` function tests if a schema exists in SQL Server. Pass the connection to SQL Server to the
    `Connection` parameter and the schema name to the `Name` parameter. Returns `$true` if the schema exists, and
    `$false otherwise.

    .EXAMPLE
    Test-YMsSqlSchema -Connection $conn -Name 'yodel'

    Demonstrates how to test if a schema exists by passing the schema name to the `Name` parameter.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema name.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $schema = Get-YMsSqlSchema -Connection $Connection -Name $Name -ErrorAction Ignore
    if (-not $schema)
    {
        return $false
    }
    return $true
}