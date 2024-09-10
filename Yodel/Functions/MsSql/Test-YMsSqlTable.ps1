
function Test-YMsSqlTable
{
    <#
    .SYNOPSIS
    Checks if a table exists in Microsoft SQL Server.

    .DESCRIPTION
    The `Test-YMsSqlTable` function tests if a table exists in SQL Server. Pass the connection to SQL Server to the
    `Connection` parameter and the table name to the `Name` parameter. Returns `$true` if the table exists, and `$false
    otherwise. Use the `PassThru` switch to return the table metadata instead of `$true`.

    .EXAMPLE
    Test-YMsSqlTable -Connection $conn -Name 'yodel'

    Demonstrates how to test if a table exists by passing the table name to the `Name` parameter.
    #>    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server. Use `Connect-YDatabase` to create a connection, or pass any ADO.NET
        # connection object.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema name of the table whose existence to test. The default is `dbo`.
        [String] $SchemaName = 'dbo',

        # The name of the table whose existence to test.
        [Parameter(Mandatory)]
        [String] $Name,

        # Return the table metadata instead of `$true` if the table exists.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $table = Get-YMsSqlTable -Connection $Connection -SchemaName $SchemaName -Name $Name -ErrorAction Ignore
    if (-not $table)
    {
        return $false
    }

    if ($PassThru)
    {
        return $table
    }

    return $true
}