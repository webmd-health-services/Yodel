
$script:moduleRoot = $PSScriptRoot

function Get-YTMSSqlConnection
{

    $conn = Connect-YDatabase -SqlServerName (Get-YTSqlServerName) -DatabaseName 'master'
    Initialize-YMsSqlDatabase -Connection $conn -Name 'Yodel'
    $conn.ChangeDatabase('Yodel')
    return $conn
}

function Get-YTSqlServerName
{
    $serverTxtPath = Join-Path -Path $script:moduleRoot -ChildPath '..\Server.txt' -Resolve -ErrorAction Ignore

    if ($serverTxtPath)
    {
        $sqlServerName = Get-Content -Path $serverTxtPath | Select-Object -First 1
    }

    if (-not $sqlServerName)
    {
        return '.'
    }

    return $sqlServerName
}

function Get-YTUserCredential
{
    [pscredential]::New('yodeltest', (ConvertTo-SecureString -String 'P@$$w0rd' -Force -AsPlainText))
}

function GivenMSSqlExtendedProperty
{
    param(
        [String] $Named,
        [String] $WithValue,
        [String] $OnSchema,
        [String] $OnTable,
        [String] $OnColumn
    )

    $setArgs = @{
        Connection = Get-YTMSSqlConnection;
        Name = $Named;
        Value = $WithValue;
    }

    if ($OnSchema)
    {
        $setArgs['SchemaName'] = $OnSchema
    }

    if ($OnTable)
    {
        $setArgs['TableName'] = $OnTable
    }

    if ($OnColumn)
    {
        $setArgs['ColumnName'] = $OnColumn
    }

    Set-YMsSqlExtendedProperty @setArgs
}

function GivenMSSqlSchema
{
    param(
        [String] $Named
    )

    $conn = Get-YTMSSqlConnection
    Initialize-YMsSqlSchema -Connection $conn -Name $named
}

function GivenMSSqlTable
{
    [CmdletBinding()]
    param(
        [String] $Named,

        [String[]] $Column
    )

    $conn = Get-YTMSSqlConnection
    if ((Test-YMsSqlTable -Connection $conn -Name $Named))
    {
        Remove-YMsSqlTable -Connection $conn -Name $Named
    }

    $ddl = @"
create table [${Named}] (
    $($Column -join ", $([Environment]::NewLine)    ")
)
"@
    Invoke-YMsSqlCommand -Connection (Get-YTMSSqlConnection) -Text $ddl -NonQuery
}

function GivenMSSqlTestUser
{
    param(
        [Parameter(Mandatory)]
        [String]$SqlServerName
    )

    $credential = Get-YTUserCredential

    $conn = Connect-YDatabase -SqlServerName $sqlServerName -DatabaseName 'master'
    $cmd = $conn.CreateCommand()
    try
    {
        $cmd.CommandText = 'if not exists (select * from [sys].[server_principals] where name = ''{0}'') create login [{0}] with password = ''P@$$w0rd''' -f $credential.UserName
        [void]$cmd.ExecuteNonQuery()

        $cmd.CommandText = 'if not exists (select * from [sys].[database_principals] where name = ''{0}'') create user [{0}] for login [{0}]' -f $credential.UserName
        [void]$cmd.ExecuteNonQuery()

        $cmd.CommandText = 'sp_addrolemember'
        $cmd.CommandType = 'StoredProcedure'
        [void]$cmd.Parameters.AddWithValue('@rolename', 'db_datareader')
        [void]$cmd.Parameters.AddWithValue('@membername', $credential.UserName)
        [void]$cmd.ExecuteNonQuery()

        Write-Output $credential
    }
    finally
    {
        $cmd.Dispose()
        $conn.Close()
    }
}

function ThenMSSqlExtendedProperty
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [String] $Named,

        [Parameter(Mandatory, ParameterSetName='OnSchema')]
        [String] $OnSchema,

        [Parameter(ParameterSetName='OnTable')]
        [String] $InSchema,

        [Parameter(Mandatory, ParameterSetName='OnTable')]
        [Parameter(Mandatory, ParameterSetName='OnColumn')]
        [String] $OnTable,

        [Parameter(Mandatory, ParameterSetName='OnColumn')]
        [String] $OnColumn,

        [String] $HasValue
    )

    $getArgs = @{
        Connection = (Get-YTMSSqlConnection);
        Name = $Named;
    }

    if ($PSCmdlet.ParameterSetName -eq 'OnSchema')
    {
        $getArgs['SchemaName'] = $OnSchema
    }
    elseif ($PSCmdlet.ParameterSetName -in @('OnTable', 'OnColumn'))
    {
        if ($InSchema)
        {
            $getArgs['SchemaName'] = $InSchema
        }
        $getArgs['TableName'] = $OnTable

        if ($PSBoundParameters.ContainsKey('OnColumn'))
        {
            $getArgs['ColumnName'] = $OnColumn
        }
    }

    $prop = Get-YMsSqlExtendedProperty @getArgs
    $prop | Should -Not -BeNullOrEmpty
    $prop.value | Should -Be $HasValue
}