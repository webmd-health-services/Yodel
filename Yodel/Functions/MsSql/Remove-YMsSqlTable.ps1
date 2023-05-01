
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

    $SchemaName, $Name = $SchemaName, $Name | ConvertTo-YMsSqlIdentifier -Connection $Connection

    $query = "drop table ${SchemaName}.${Name}"
    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query
    if (-not $result)
    {
        $msg = "Table ${SchemaName}.${Name} does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result
}