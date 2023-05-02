
function Set-YMsSqlExtendedProperty
{
    <#
    .SYNOPSIS
    Adds or updates Microsoft SQL Server extended properties.

    .DESCRIPTION
    The `Set-YMsSqlExtendedProperty` function adds or updates extended property metadata for objects in SQL Server. It
    calls the `fn_addextendedproperty` to add a new extended property and `fn_updateextendedproperty` to update an
    existing extended property. An extended property is updated only if its value has changed. Pass the connection to
    Microsoft SQL Server to the connection parameter, the name of the extended property to the `Name` parameter and the
    value to the `Value` property.

    To set an extended property for an arbitrary object, pass the appropriate level 0, 1, and 2 types and names for that
    object to the `Level0Type`, `Level0Name`, `Level1Type`, `Level1Name`, `Level2Type`, and `Level2Name` parameters. The
    value `$null` is allowed for any level type/name parameter.

    To set an extended property for a schema, pass the schema's name to the `SchemaName` parameter.

    To set an extended property for a table, pass the table's name and schema name to the `TableName` and `SchemaName`
    parameters, respectively.

    To set an extended property for a column on a table, pass the column's name, table name, and table's schema name to
    the `ColumnName`, `TableName`, and `SchemaName` parameters, respectively.

    .EXAMPLE
    Set-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -Name 'Yodel_Example' -Value '1'

    Demonstrates how to set a schema extended property by passing the schema name to the `SchemaName` parameter.

    .EXAMPLE
    Set-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1' -Name 'Yodel_Example' -Value '2'

    Demonstrates how to set a table extended properties by passing the table name to the `TableName` parameter and the
    table's schema to the `SchemaName` parameter.

    .EXAMPLE
    Set-YMsSqlExtendedProperty -Connection $conn -SchemaName 'yodel' -TableName 'Table_1' -ColumnName 'id' -Name 'Yodel_Example' -Value '3'

    Demonstrates how to set a table column extended property by passing the column name to the `ColumnName` parameter,
    the columns's table name to the `TableName` parameter and the table's schema name to the `SchemaName` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='Raw')]
    param(
        # The connection to Microsoft SQL Server.
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        # The schema name whose extended property to set. Or the schema name of the table whose extended propert to
        # set. Defaults to `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForSchema')]
        [Parameter(ParameterSetName='ForTable')]
        [Parameter(ParameterSetName='ForTableColumn')]
        [String] $SchemaName,

        # The table name whose extended property to set, or the table name of the column whose extended property to
        # set. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForTable')]
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $TableName,

        # The column name whose extended property to set. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $ColumnName,

        # The name of the extended property to set. Defalt is `NULL`.
        [Parameter(Mandatory)]
        [String] $Name,

        # The name of the extended property to set. Defalt is `NULL`.
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [String] $Value,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level0_object_type`
        # parameter. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Type,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level0_object_name`
        # parameter. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Name,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level1_object_type`
        # parameter. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Type,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level1_object_name`
        # parameter. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Name,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level2_object_type`
        # parameter. Default is `NULL`.
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Type,

        # The value for the `fn_addextendedproperty` or `fn_updateextededproperty` function's `level2_object_name`
        # parameter. Default is `NULL`.
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

        $setArgs = @{
            Connection = $Connection;
            Name = $Name;
            Value = $Value;
            Level0Type = 'schema';
            Level0Name = $SchemaName;
        }

        if ($PSCmdlet.ParameterSetName -ne 'ForSchema')
        {
            $setArgs['Level1Type'] = 'table'
            $setArgs['Level1Name'] = $TableName

            if ($PSBoundParameters.ContainsKey('ColumnName'))
            {
                $setArgs['Level2Type'] = 'column'
                $setArgs['Level2Name'] = $ColumnName
            }
        }

        return Set-YMsSqlExtendedProperty @setArgs
    }

    $propArgs = @{}
    foreach ($argPosition in '0', '1', '2')
    {
        foreach ($argKind in @('Type', 'Name'))
        {
            $argName = "Level${argPosition}${argKind}"
            if (-not $PSBoundParameters.ContainsKey($argName))
            {
                continue
            }
            $propArgs[$argName] = $PSBoundParameters[$argName]
        }
    }
    $prop = Get-YMsSqlExtendedProperty -Connection $Connection -Name $Name @propArgs -ErrorAction Ignore
    if ($prop -and $prop.value -eq $Value)
    {
        return
    }

    $sprocArgs = @{
        '@name' = $Name;
        '@value' = $Value;
    }
    foreach ($argPosition in '0', '1', '2')
    {
        foreach ($argKind in @('type', 'name'))
        {
            $argName = "level${argPosition}${argKind}"
            if (-not $PSBoundParameters.ContainsKey($argName))
            {
                continue
            }
            $sprocArgs["@${argName}"] = $PSBoundParameters[$argName]
        }
    }

    $sprocName = 'sp_updateextendedproperty'
    if ($null -eq $prop)
    {
        $sprocName = 'sp_addextendedproperty'
    }

    Invoke-YMsSqlCommand -Connection $Connection `
                         -Text $sprocName `
                         -Parameter $sprocArgs `
                         -Type ([Data.CommandType]::StoredProcedure)
}
