
function Test-YMsSqlSchema
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $schema = Get-YMsSqlSchema -Connection $Connection -Name $Name -ErrorAction Ignore
    if (-not $schema)
    {
        return $false
    }
    return $true
}