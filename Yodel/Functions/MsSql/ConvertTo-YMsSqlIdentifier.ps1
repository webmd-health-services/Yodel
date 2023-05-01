
function ConvertTo-YMsSqlIdentifier
{
    <#
    .SYNOPSIS
    Converts a string to a Microsoft SQL Server quoted identifier.

    .DESCRIPTION
    The `ConvertTo-YMsSqlIdentifier` function converts a string to a quoted identifier. Pipe the name to the function
    (or pass it to the `ImputObject` parameter). The function calls SQL Server's `QUOTENAME` function to quote and
    escape the name. The value is passed to the query as a parameter to avoid SQL injection attacks.

    Use this function if embedding object names in strings containing raw SQL.

    .EXAMPLE
    'hello[]world' | ConvertTo-YMsSqlIdentifier -Connection $conn

    Demonstrates how to pipe values to this function. In this example, the function calls
    `select quotename('hello[]world')`, which would return the string `[hello[]]world]`.
    #>
    [CmdletBinding()]
    param(
        # The connection to use to run the `quotename` query.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The value to convert.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $InputObject
    )

    process
    {
        return Invoke-YMsSqlCommand -Connection $Connection `
                                    -Text 'select QUOTENAME(@name)' `
                                    -Parameter @{ '@name' = $InputObject } `
                                    -AsScalar
    }
}