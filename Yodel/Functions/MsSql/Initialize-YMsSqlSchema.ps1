
function Initialize-YMsSqlSchema
{
    <#
    .SYNOPSIS
    Ensures a schema exists in a Microsoft SQL Server database.

    .DESCRIPTION
    The `Initialize-YMsSqlSchema` function creates a schema in a SQL Server database if that schema doesn't already
    exist. Pass the connection to the SQL server to use to the `Connection` parameter and the name of the schema to
    the `Name` parameter.

    .EXAMPLE
    Initialize-YMsSqlSchema -Connection $conn -Name 'Yodel'

    Demonstrates how to use this function. In this example, the `Yodel` schema will be created, but only if it doesn't
    already exist.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema's name.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (Test-YMsSqlSchema -Connection $Connection -Name $Name)
    {
        return
    }

    $Name = $Name | ConvertTo-YMsSqlIdentifier -Connection $Connection
    $query = "create schema ${Name}"
    Invoke-YMsSqlCommand -Connection $Connection -Text $query -NonQuery
}