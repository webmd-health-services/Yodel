
function Initialize-YMsSqlDatabase
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

    $query = "select 1 from sys.databases where name='${Name}'"
    $dbExists = Invoke-YMsSqlCommand -Connection $Connection -Text $query -AsScalar
    if (-not $dbExists)
    {
        $query = "create database [${Name}]"
        Invoke-YMsSqlCommand -Connection $Connection -Text $query -NonQuery
    }
}