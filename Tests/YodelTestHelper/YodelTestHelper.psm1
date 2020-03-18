
function Get-YTSqlServerName
{
    Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Server.txt' -Resolve) |
        Select-Object -First 1
}

function Get-YTUserCredential
{
    [pscredential]::New('yodeltest', (ConvertTo-SecureString -String 'P@$$w0rd' -Force -AsPlainText))
}

function GivenTestUser
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
