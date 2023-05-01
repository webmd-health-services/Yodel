
function Get-YMsSqlTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        [String] $SchemaName = 'dbo',

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
    t.name=@name and s.schema_name=@schemaName
"@
    $queryArgs = @{
        '@name' = $Name;
        '@schemaName' = $SchemaName;
    }
    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter $queryArgs
    if (-not $result)
    {
        $msg = "Table [${SchemaNaem}].[${Name}] does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result
}