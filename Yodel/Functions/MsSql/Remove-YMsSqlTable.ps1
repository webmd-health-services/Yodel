
function Remove-YMsSqlTable
{
    <#
    .SYNOPSIS
    Drops a table from Microsoft SQL Server.

    .DESCRIPTION
    The `Remove-YMsSqlTable` function drops a table in SQL Server. Pass the connection to SQL Server to the `Connection`
    parameter and the table name to the `Name` parameter. If the table doesn't exist, the function writes an error.

    If the table isn't in the `dbo` schema, pass its schema to the `SchemaName` parameter.

    .EXAMPLE
    Remove-YMsSqlTable -Connection $conn -Name 'Table_2'

    Demonstrates how to remove the `[dbo].[Table_2]` table.

    .EXAMPLE
    Remove-YMsSqlTable -Connection $conn -SchemaName 'yodel' -Name 'Table_2'

    Demonstrates how to remove the `[yodel].[Table_2]` table.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The table's schema name. Defaults to `dbo`.
        [String] $SchemaName = 'dbo',

        # The table's name.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not (Test-YMsSqlTable -Connection $Connection -SchemaName $SchemaName -Name $Name))
    {
        $msg = "Table ${SchemaName}.${Name} does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $SchemaName, $Name = $SchemaName, $Name | ConvertTo-YMsSqlIdentifier -Connection $Connection
    $query = "drop table ${SchemaName}.${Name}"
    Invoke-YMsSqlCommand -Connection $Connection -Text $query -NonQuery
}