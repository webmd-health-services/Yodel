
function Set-YMsSqlExtendedProperty
{
    [CmdletBinding(DefaultParameterSetName='Raw')]
    param(
        [Parameter(Mandatory)]
        [Data.Common.DbConnection] $Connection,

        [Parameter(Mandatory, ParameterSetName='ForSchema')]
        [Parameter(ParameterSetName='ForTable')]
        [Parameter(ParameterSetName='ForTableColumn')]
        [String] $SchemaName,

        [Parameter(Mandatory, ParameterSetName='ForTable')]
        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $TableName,

        [Parameter(Mandatory, ParameterSetName='ForTableColumn')]
        [String] $ColumnName,

        [Object] $Name,

        [Object] $Value,

        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Type,

        [Parameter(Mandatory, ParameterSetName='RawL0')]
        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level0Name,

        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Type,

        [Parameter(Mandatory, ParameterSetName='RawL1')]
        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level1Name,

        [Parameter(Mandatory, ParameterSetName='RawL2')]
        [AllowNull()]
        [Object] $Level2Type,

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
        $setArgs = @{
            Connection = $Connection;
            Name = $Name;
            Value = $Value;
            Level0Type = 'schema';
            Level0Name = $SchemaName;
        }

        if ($PSCmdlet.ParameterSetName -ne 'ForSchema')
        {
            $l1Type = 'table'
            $l1Name = $TableName

            $setArgs['Level1Type'] = $l1Type
            $setArgs['Level1Name'] = $l1Name

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
