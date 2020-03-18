
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

[Data.Common.DbConnection]$connection = $null
$sqlServerName = Get-YTSqlServerName

function Init
{
    if( $connection -and $connection.State -ne [Data.ConnectionState]::Closed )
    {
        Write-Error -Message ('The last test didn''t call the Reset function. The connection from the last test is still open. Please add `AfterEach { Reset }` to the previous test.')
        $connection.Close()
    }
    $script:connection = $null
}

function Reset
{
    if( $connection )
    {
        $connection.Close()
    }
}

function ThenConnectionOpened
{
    $connection.State | Should -Be 'Open'
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = 'select 1'
    $cmd.ExecuteScalar() | Should -Be 1
    $cmd.Dispose()
}

function WhenOpeningConnection
{
    param(
        [Parameter(Mandatory,ParameterSetName='SqlServer')]
        $ToServer,

        [Parameter(Mandatory,ParameterSetName='SqlServer')]
        $ToDatabase,

        [Parameter(ParameterSetName='SqlServer')]
        [pscredential]$WithCredential,

        [Parameter(Mandatory,ParameterSetName='Provider')]
        $WithProvider,

        $WithConnectionString
    )

    $optionalParams = @{}

    if( $WithConnectionString )
    {
        $optionalParams['ConnectionString'] = $WithConnectionString
    }
    if( $WithProvider )
    {
        $optionalParams['Provider'] = $WithProvider
    }
    else
    {
        $optionalParams['SqlServerName'] = $ToServer
        $optionalParams['DatabaseName'] = $ToDatabase
        if( $WithCredential )
        {
            $optionalParams['Credential'] = $WithCredential
        }
    }


    $script:connection = Connect-YDatabase @optionalParams
}

Describe 'Connect-YDatabase.when connecting to SQL Server' {
    AfterEach { Reset }
    It 'should open the connection' {
        Init
        WhenOpeningConnection -ToServer $sqlServerName -ToDatabase 'master'
        ThenConnectionOpened
    }
}

Describe 'Connect-YDatabase.when connecting to SQL Server with credential' {
    AfterEach { Reset }
    It 'should open the connection' {
        Init
        $credential = GivenTestUser -SqlServerName $sqlServerName
        WhenOpeningConnection -ToServer $sqlServerName -ToDatabase 'master' -WithCredential $credential
        ThenConnectionOpened
    }
}

Describe 'Connect-YDatabase.when connecting with custom provider' {
    AfterEach { Reset }
    Context 'SqlClient' {
        It 'should open the connection' {
            Init
            WhenOpeningConnection -WithProvider ([Data.SqlClient.SqlClientFactory]::Instance) `
                                  -WithConnectionString ('Server={0};Database=master;Integrated Security=True' -f $sqlServerName)
            ThenConnectionOpened
        }
    }
    # Ole provider isn't on AppVeyor. We should figure out why at some point.
    if( -not (Test-Path -Path 'env:APPVEYOR') )
    {
        Context 'OleDb' {
            It 'should open the connection' {
                Init
                WhenOpeningConnection -WithProvider ([Data.OleDb.OleDbFactory]::Instance) `
                                    -WithConnectionString ('Provider=sqloledb;Data Source={0};Initial Catalog=master;Integrated Security=SSPI' -f $sqlServerName)
                ThenConnectionOpened
            }
        }
    }
    Context 'Odbc' {
        It 'should open the connection' {
            Init
            WhenOpeningConnection -WithProvider ([Data.Odbc.OdbcFactory]::Instance) `
                                  -WithConnectionString ('Driver={{SQL Server}};Server={0};Database=master;Trusted_Connection=Yes' -f $sqlServerName)
            ThenConnectionOpened
        }
    }
}

Reset