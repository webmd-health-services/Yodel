
function Get-YMsSqlExtendedProperty
{
    <#
    .SYNOPSIS
    Gets Microsoft SQL Server extended properties.

    .DESCRIPTION
    The `Get-YMsSqlExtendedProperty` function gets extended property metadata for objects in a Microsoft SQL Server. It
    calls the `fn_listextendedproperty` to get the extended properties. To get all extended properties for arbitrary
    objects, pass appropriate values level 0, 1, and types and names to the `Level0Type`, `Level0Name`, `Level1Type`,
    `Level1Name`, `Level2Type`, and `Level2Name` parameters. To get a specific extended property, pass its name to the
    `Name` parameter.

    To get extended properties for a schema, pass the schema's name to the `SchemaName` parameter.

    To get extended properties for a table, pass the table's name and schema name to the `TableName` and `SchemaName`
    parameters, respectively.

    To get extended properties for a column on a table, pass the column's name, table name, and table's schema name to
    the `ColumnName`, `TableName`, and `SchemaName` parameters, respectively.

    To use `NULL` as the value for any of the `fn_listextendedproperty` level or name parameters, omit the argument or
    pass `$null`.

    To use `default` as the value for any of the `fn_listextendedproperty` level or name parameters, pass
    `[Yodel_MsSql_QueryKeyword]::Default`.

    .EXAMPLE
    Get-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel'

    Demonstrates how to get a schema's extended properties by passing the schema name to the `SchemaName` parameter.

    .EXAMPLE
    Get-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1'

    Demonstrates how to get a table's extended properties by passing the table name to the `TableName` parameter and the
    table's schema to the `SchemaName` parameter.

    .EXAMPLE
    Get-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1' -ColumnName 'id

    Demonstrates how to get a table column's extended properties by passing the column name to the `ColumnName`
    parameter and the columns's table to the `TableName` parameter and the table's schema to the `SchemaName` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='Raw')]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema name whose extended properties to get. Or the schema name of the table whose extended properties to
        # get. Defaults to `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForSchema')]
        [Parameter(ParameterSetName='ForTable')]
        [Parameter(ParameterSetName='ForTableColumn')]
        [String] $SchemaName,

        # The table name whose extended properties to get, or the table name of the column whose extended properties to
        # get. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForTable')]
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $TableName,

        # The column name whose extended properties to get. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $ColumnName,

        # The name of the extended property to get. Defalt is `NULL`. To use `default` as the value, pass
        #  `[Yodel_MsSql_QueryKeyword]::Default`.
        [Object] $Name,

        # The value for the `fn_listextendedproperty` function's `level0_object_type` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Type,

        # The value for the `fn_listextendedproperty` function's `level0_object_name` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Name,

        # The value for the `fn_listextendedproperty` function's `level1_object_type` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Type,

        # The value for the `fn_listextendedproperty` function's `level1_object_name` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Name,

        # The value for the `fn_listextendedproperty` function's `level2_object_type` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Type,

        # The value for the `fn_listextendedproperty` function's `level2_object_name` parameter. Default is `NULL`. To
        # use `default` as the value, pass `[Yodel_MsSql_QueryKeyword]::Default`.
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -notlike 'Raw*')
    {
        if (-not $SchemaName)
        {
            $SchemaName = 'dbo'
        }

        $l1Type = $l1Name = $l2Type = $l2Name = $null

        if ($PSCmdlet.ParameterSetName -ne 'ForSchema')
        {
            $l1Type = 'table'
            $l1Name = $TableName

            $l2Type = $null
            $l2Name = $null
            if ($PSBoundParameters.ContainsKey('ColumnName'))
            {
                $l2Type = 'column'
                $l2Name = $ColumnName
            }
        }

        return Get-YMsSqlExtendedProperty -Connection $Connection `
                                         -Name $Name `
                                         -Level0Type 'schema' `
                                         -Level0Name $SchemaName `
                                         -Level1Type $l1Type `
                                         -Level1Name $l1Name `
                                         -Level2Type $l2Type `
                                         -Level2Name $l2Name
    }

    $parameter = @{}
    function Get-ArgValue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [AllowNull()]
            [Object] $InputObject
        )

        if ($null -eq $InputObject)
        {
            return 'NULL'
        }

        if ($InputObject -eq [Yodel_MsSql_QueryKeyword]::Default)
        {
            return 'default'
        }

        $paramName = "@param$($parameter.Count)"
        $parameter[$paramName] = $InputObject
        return $paramName
    }

    $nameArg = $Name | Get-ArgValue
    $l0TypeArg = $Level0Type | Get-ArgValue
    $l0NameArg = $Level0Name | Get-ArgValue
    $l1TypeArg = $Level1Type | Get-ArgValue
    $l1NameArg = $Level1Name | Get-ArgValue
    $l2TypeArg = $Level2Type | Get-ArgValue
    $l2NameArg = $Level2Name | Get-ArgValue

    $query = "select * from sys.fn_listextendedproperty(${nameArg}, ${l0TypeArg}, ${l0NameArg}, ${l1TypeArg}, ${l1NameArg}, ${l2TypeArg}, ${l2NameArg})"
    $result = Invoke-YMsSqlCommand -Connection $Connection -Text $query -Parameter $parameter

    if ($result)
    {
        return $result
    }

    $msg = 'There are no extended properties on '

    if ($PSCmdlet.ParameterSetName -eq 'Raw')
    {
        $msg = "${msg}database ""$($Connection.Database)"""
    }

    function Get-LevelMessage
    {
        param(
            [Parameter(Mandatory)]
            [AllowNull()]
            [Object] $Type,

            [Parameter(Mandatory)]
            [AllowNull()]
            [Object] $Name
        )

        if ($null -eq $Type -or $Type -eq [Yodel_MsSql_QueryKeyword]::Default)
        {
            return ''
        }

        if ($null -eq $Name -or $Name -eq [Yodel_MsSql_QueryKeyword]::Default)
        {
            return "all ${Type}"
        }

        return "${Type} ""${Name}"""
    }

    $seperator = ''
    if ($PSCmdlet.ParameterSetName -in @('RawL0', 'RawL1', 'RawL2'))
    {
        $levelMsg = Get-LevelMessage -Type $Level0Type -Name $Level0Name
        $msg = "${msg}${levelMsg}"
        if ($levelMsg)
        {
            $seperator = ', '
        }
    }

    if ($PSCmdlet.ParameterSetName -in @('RawL1', 'RawL2'))
    {
        $levelMsg = Get-LevelMessage -Type $Level1Type -Name $Level1Name
        if ($levelMsg)
        {
            $msg = "${msg}${seperator}${levelMsg}"
            $seperator = ', '
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'RawL2')
    {
        $levelMsg = Get-LevelMessage -Type $Level2Type -Name $Level2Name
        if ($levelMsg)
        {
            $msg = "${msg}${seperator}${levelMsg}"
        }
    }

    Write-Error -Message "${msg}." -ErrorAction $ErrorActionPreference
}
