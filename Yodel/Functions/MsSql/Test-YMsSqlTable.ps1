
function Test-YMsSqlTable
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

    $table = Get-YMsSqlTable -Connection $Connection -SchemaName $SchemaName -Name $Name -ErrorAction Ignore
    if (-not $table)
    {
        return $false
    }
    return $true
}