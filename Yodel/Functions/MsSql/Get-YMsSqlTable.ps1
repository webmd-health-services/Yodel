
function Get-YMsSqlTable
{
    <#
    .SYNOPSIS
    Gets metadata about a table from Microsoft SQL Server.

    .DESCRIPTION
    the `Get-YMsSqlTable` function gets metadata about a table from Microsoft SQL Server. Pass the connection to SQL
    Server to the `Connection` parameter and the table name to the `Name` parameter. The function returns the result of
    select all the columns for that table from `sys.tables`.

    If the table isn't in the `dbo` schema, pass its schema name to the `SchemaName` parameter.

    .EXAMPLE
    Get-YMsSqlTable -Connection $conn -Name 'Table_1'

    Demonstrates how to get metadata for a table in the `dbo` schema. In this example, returns the `[dbo].[Table_1]`
    table's record from `sys.tables`.

    .EXAMPLE
    Get-YMsSqlTable -Connection $conn -SchemaName 'yodel' -Name 'Table_1'

    Demonstrates how to get metadata for a table in a custom schema. In this example, returns the `[yodel].[Table_1]`
    table's record from `sys.tables`.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The table's schema. Defaults to `dbo`.
        [String] $SchemaName = 'dbo',

        # The table name.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $query = @"
select
    t.*
from
    sys.tables t
        join
    sys.schemas s
            on t.schema_id=s.schema_id
where
    t.name=@name and s.name=@schemaName
"@
    $queryArgs = @{
        '@name' = $Name;
        '@schemaName' = $SchemaName;
    }
    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter $queryArgs
    if (-not $result)
    {
        $msg = "Table [${SchemaName}].[${Name}] does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result
}