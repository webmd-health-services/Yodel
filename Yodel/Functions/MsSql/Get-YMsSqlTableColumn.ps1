
function Get-YMsSqlTableColumn
{
    <#
    .SYNOPSIS
    Gets metadata about a table's columns from Microsoft SQL Server.

    .DESCRIPTION
    The `Get-YMsSqlTableColumn` function gets metadata about a table's columns from Microsoft SQL Server. Pass the
    connection to SQL Server to the `Connection` parameter and the table name to the `Name` parameter. The function
    returns the result of select all the columns for that table from `sys.tables`.

    If the table isn't in the `dbo` schema, pass its schema name to the `SchemaName` parameter.

    .EXAMPLE
    Get-YMsSqlTableColumn -Connection $conn -Name 'Table_1'

    Demonstrates how to get metadata for a table's column in the `dbo` schema. In this example, returns the
    `[dbo].[Table_1]` table's record from `sys.tables`.

    .EXAMPLE
    Get-YMsSqlTableColumn -Connection $conn -SchemaName 'yodel' -Name 'Table_1'

    Demonstrates how to get metadata for a table's columns in a custom schema. In this example, returns the
    `[yodel].[Table_1]` table's record from `sys.tables`.
    #>
    [CmdletBinding()]
    param(
        # The connection to Microsoft SQL Server. Use `Connect-YDatabase` to create a connection, or pass any ADO.NET
        # connection object.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The table's schema. Defaults to `dbo`.
        [String] $SchemaName = 'dbo',

        # The table name.
        [Parameter(Mandatory)]
        [String] $TableName,

        # The name of the column to get. By default, all of the table's columns are returned.
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $queryArgs = @{
        '@tableName' = $TableName;
        '@schemaName' = $SchemaName;
    }

    $nameClause = ''
    if ($Name)
    {
        $nameClause = " and c.name=@name"
        $queryArgs['@name'] = $Name
    }

    $query = @"
select
    c.*
from
    sys.columns c
        join
    sys.tables t
            on c.object_id=t.object_id
        join
    sys.schemas s
            on t.schema_id=s.schema_id
where
    t.name=@tableName and s.name=@schemaName${nameClause}
"@

    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter $queryArgs
    if (-not $result)
    {
        $msg = "Table [${SchemaName}].[${TableName}] does not exist."
        if ($Name)
        {
            $msg = "Column [${Name}] does not exist on table [${SchemaName}].[${TableName}]."
        }

        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result
}