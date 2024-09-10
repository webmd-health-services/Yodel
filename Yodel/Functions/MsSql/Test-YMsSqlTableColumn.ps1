
function Test-YMsSqlTableColumn
{
    <#
    .SYNOPSIS
    Checks if a column exists on a table in Microsoft SQL Server.

    .DESCRIPTION
    The `Test-YMsSqlTableColumn` function tests if a column exists on a table in SQL Server. Pass the connection to SQL
    Server to the `Connection` parameter, the table name to the `TableName` parameter, and the column name to the
    `ColumnName` parameter. Returns `$true` if the column exists, and `$false` otherwise.

    If the table is in a custom
    schema, pass the schema name to the `SchemaName` parameter.

    .EXAMPLE
    Test-YMsSqlTableColumn -Connection $conn -TableName 'yodel' -Name 'id'

    Demonstrates how to test if a column exists on a table by passing the table name to the `TableName` parameter and
    the column name to the `Name` parameter.
    #>
    [CmdletBinding()]
    param(
        # The database connection. Use `Connect-YDatabase` to create a connection.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The table's schema name. The default is `dbo`.
        [String] $SchemaName = 'dbo',

        # The name of the table whose columns to test.
        [Parameter(Mandatory)]
        [String] $TableName,

        # The name of the column whose existence to test.
        [Parameter(Mandatory)]
        [String] $Name,

        # If the column exists, return it instead of `$true`.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $column = Get-YMsSqlTableColumn -Connection $Connection `
                                    -SchemaName $SchemaName `
                                    -TableName $TableName `
                                    -Name $Name `
                                    -ErrorAction Ignore
    if (-not $column)
    {
        return $false
    }

    if ($PassThru)
    {
        return $column
    }

    return $true
}