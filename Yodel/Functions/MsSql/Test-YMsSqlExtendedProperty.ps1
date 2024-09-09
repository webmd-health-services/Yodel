
function Test-YMsSqlExtendedProperty
{
    <#
    .SYNOPSIS
    Tests for the existence of Microsoft SQL Server extended properties.

    .DESCRIPTION
    The `Test-YMsSqlExtendedProperty` function tests if an extended property for an object exists in SQL Server. It
    calls the `fn_listextendedproperty` to get the extended property. Pass the connection to Microsoft SQL Server to the
    connection parameter and the name of the extended property to the `Name` parameter.

    To test for the existence of an extended property for an arbitrary object, pass the appropriate level 0, 1, and 2
    types and names for that object to the `Level0Type`, `Level0Name`, `Level1Type`, `Level1Name`, `Level2Type`, and
    `Level2Name` parameters. The value `$null` is allowed for any level type/name parameter. Use
    `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value for any `fn_listextendedproperty` parameter.

    To test for the existence of an extended property for a schema, pass the schema's name to the `SchemaName`
    parameter.

    To test for the existence of an extended property for a table, pass the table's name and schema name to the
    `TableName` and `SchemaName` parameters, respectively.

    To test for the existence of an extended property for a column on a table, pass the column's name, table name, and
    table's schema name to the `ColumnName`, `TableName`, and `SchemaName` parameters, respectively.

    Returns `$true` if the exteneded property exists. Otherwise, returns `$false`. Use the `PassThru` switch to return
    the property metadata instead of `$true`.

    .EXAMPLE
    Test-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -Name 'Yodel_Example'

    Demonstrates how to test if a schema extended property exists by passing the schema name to the `SchemaName`
    parameter.

    .EXAMPLE
    Test-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1' -Name 'Yodel_Example'

    Demonstrates how to test if a table extended properties exists by passing the table name to the `TableName`
    parameter and the table's schema to the `SchemaName` parameter.

    .EXAMPLE
    Test-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1' -ColumnName 'id' -Name 'Yodel_Example'

    Demonstrates how to test if a table column extended property exists by passing the column name to the `ColumnName`
    parameter, the columns's table name to the `TableName` parameter and the table's schema name to the `SchemaName`
    parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='Raw')]
    param(
        # The connection to Microsoft SQL Server. Use `Connect-YDatabase` to create a connection, or pass any ADO.NET
        # connection object.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema name whose extended property to test, or the schema name of the table whose extended property to
        # test.
        [Parameter(Mandatory, ParameterSetName='ForSchema')]
        [Parameter(ParameterSetName='ForTable')]
        [Parameter(ParameterSetName='ForTableColumn')]
        [String] $SchemaName,

        # The table name whose extended property to test, or the table name of the column whose extended property to
        # test.
        [Parameter(Mandatory, ParameterSetName='ForTable')]
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $TableName,

        # The column name whose extended property to test.
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $ColumnName,

        # The name of the extended property to test.
        [Parameter(Mandatory)]
        [String] $Name,

        # The value for the `fn_listextendedproperty` function's `level0_object_type` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Type,

        # The value for the `fn_listextendedproperty` function's `level0_object_name` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Name,

        # The value for the `fn_listextendedproperty` function's `level1_object_type` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Type,

        # The value for the `fn_listextendedproperty` function's `level1_object_name` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Name,

        # The value for the `fn_listextendedproperty` function's `level2_object_type` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Type,

        # The value for the `fn_listextendedproperty` function's `level2_object_name` parameter. Default is `NULL`. Use
        # `[Yodel_MsSql_QueryKeyword]::Default` to pass `default` as the value.
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Name,

        # Return extended property metadata instead of `$true` if the property exists.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $getArgs = $PSBoundParameters
    [void]$getArgs.Remove('PassThru')

    $property = Get-YMsSqlExtendedProperty @getArgs -ErrorAction Ignore
    if (-not $property)
    {
        return $false
    }

    if ($PassThru)
    {
        return $property
    }

    return $true
}
