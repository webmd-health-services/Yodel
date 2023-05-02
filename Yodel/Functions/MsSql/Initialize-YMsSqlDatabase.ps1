
function Initialize-YMsSqlDatabase
{
    <#
    .SYNOPSIS
    Ensures a Microsoft SQL Server database exists.

    .DESCRIPTION
    The `Initialize-YMsSqlDatabase` function creates a database in Microsoft SQL Server if it doesn't already exist.
    Pass the connection to SQL Server to the `Connection` parameter and the name of the database to the `Name`
    parameter. If the database doesn't exist (i.e. there's no record for it in `sys.databases`), it is created. If the
    function completes without writing or throwing an error, the database will exist.

    .EXAMPLE
    Initialize-YMsSqlDatabase -Connection $conn -Name 'Yodel'

    Demonstrates how to use this function to ensure a database exists. In this example, `Initialize-YMsSqlDatabase` will
    create the `Yodel` database if and only if the `Yodel` database doesn't exist.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The database name.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $query = 'select 1 from sys.databases where name=@name'
    $dbExists = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter @{ '@name' = $Name } -AsScalar
    if ($dbExists)
    {
        return
    }

    $Name = $Name | ConvertTo-YMsSqlIdentifier -Connection $Connection
    $query = "create database ${Name}"
    Invoke-YMsSqlCommand -Connection $Connection -Text $query -NonQuery
}