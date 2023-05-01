
function Get-YMsSqlSchema
{
    <#
    .SYNOPSIS
    Gets schema metadata from Microsoft SQL Server.

    .DESCRIPTION
    The `Get-YMsSqlSchema` function gets schema metadata from Microsoft SQL Server. Pass the connection to SQL Server to
    the `Connection` parameter and the name of the schema to the `Name` parameter. The function returns all columns
    from `sys.schemas` for the given schema.

    .EXAMPLE
    Get-YMsSqlSchema -Connection $conn -Name 'dbo'

    Demonstrates how to use this function. In this example, all columns from the `sys.schemas` table for the `dbo`
    schema will be returned.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $query = 'select * from sys.schemas where name = @schemaName'
    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter @{ '@schemaName' = $Name }
    if (-not $result)
    {
        $msg = "Schema ""${Name}"" does not exist."
        Write-Error $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result
}