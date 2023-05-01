
function Initialize-YMsSqlSchema
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

    if (Test-YMsSqlSchema -Connection $Connection -Name $Name)
    {
        return
    }

    $query = "create schema [${Name}]"
    Invoke-YMsSqlCommand -Connection $Connection -Text $query -NonQuery
}