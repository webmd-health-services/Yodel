
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

$sqlServerName = Get-YTSqlServerName
$masterConn = Connect-YDatabase -SqlServerName $sqlServerName -Database 'master'

Describe 'Invoke-YDbCommand' {
    It 'should return rows' {
        $row = Invoke-YDbCommand -Connection $masterConn -Text 'select * from sys.system_views'
        $row | Should -Not -BeNullOrEmpty
        # Make sure objects get properties for each column.
        $row[0] | Get-Member 'name' | Should -Not -BeNullOrEmpty
        $row[0] | Get-Member 'object_id' | Should -Not -BeNullOrEmpty
    }

    It 'should return nameless columns' {
        $row = Invoke-YDbCommand -Connection $masterConn -Text 'select 1, 2, 3'
        $row | Should -Not -BeNullOrEmpty
        $row | Should -HaveCount 1
        $row.Column0 | Should -Be 1
        $row.Column1 | Should -Be 2
        $row.Column2 | Should -Be 3
    }

    It 'should return scalars' {
        $val = Invoke-YDbCommand -Connection $masterConn -Text 'select 1' -AsScalar
        $val | Should -Be 1
    }

    It 'should return nothing if no rows affected' {
        $value = Invoke-YDbCommand -Connection $masterConn -Text 'select * from sys.system_views' -NonQuery
        $value | Should -BeNullOrEmpty
    }

    It 'should parameterize query' {
        $value = Invoke-YDbCommand -Connection $masterConn -Text 'select * from [sys].[system_views] where name = @view_name' -Parameter @{ 'view_name' = 'system_views'; }
        $value | Should -Not -BeNullOrEmpty
        $value | Should -HaveCount 1
        $value.name | Should -Be 'system_views'
    }

    It 'should execute non query' {
        $cmd = 'if not exists (select * from sys.tables where name = ''YodelTable'') create table [YodelTable] (id int not null identity, name nvarchar not null)'
        Invoke-YDbCommand -Connection $masterConn -Text $cmd -NonQuery | Should -BeNullOrEmpty
        for( $idx = 0; $idx -lt 5; ++$idx )
        {
            $cmd = 'insert into YodelTable (name) values (''{0}'')' -f $idx
            Invoke-YDbCommand -Connection $masterConn -Text $cmd -NonQuery | Should -Be 1
        }

        $rowsAffected = Invoke-YDbCommand -Connection $masterConn -Text 'delete from YodelTable' -NonQuery
        $rowsAffected | Should -Be 5
    }

    It 'should execute stored procedures' {
        $table = Invoke-YDbCommand -Connection $masterConn -Text 'select * from sys.tables' | Select-Object -First 1
        $result = Invoke-YDbCommand -Connection $masterConn -Text 'sp_tables' -Parameter @{ '@table_name' = $table.name } -Type ([Data.CommandType]::StoredProcedure)
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result.TABLE_NAME | Should -Be $table.name
    }

    It 'should format verbose messages' {
        $msg = Invoke-YDbCommand -Connection $masterConn -Text ('WAITFOR{0}DELAY{0}''00:00:01''' -f [Environment]::NewLine) -NonQuery -Verbose 4>&1
        $msg | Write-Verbose  # I want to see them so they look right.
        $msg | Should -HaveCount 3
        $msg[0] | Should -Match ' 1s +\d+ms  WAITFOR'
        $msg[1] | Should -Be '           DELAY'
        $msg[2] | Should -Be '           ''00:00:01'''
    }

    It 'should not output verbose message if verbose is off' {
        $VerbosePreference = 'Continue'
        $msg = Invoke-YDbCommand -Connection $masterConn -Text 'WAITFOR DELAY ''00:00:00.001''' -NonQuery -Verbose:$false 4>&1
        $msg | Write-Verbose  # I want to see them so they look right.
        $msg | Should -BeNullOrEmpty
    }

    It 'should respect user''s timeout' {
        $Global:Error.Clear()
        Invoke-YDbCommand -Connection $masterConn -Text 'WAITFOR DELAY ''00:00:02''' -Timeout 2 -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'execution timeout expired'
    }

    It 'should respect Ignore error action preference and preserve error' {
        $Global:Error.Clear()
        Invoke-YDbCommand -Connection $masterConn -Text 'WAITFOR DELAY ''00:00:02''' -Timeout 2 -ErrorAction Ignore
        $Global:Error | Should -HaveCount 1
        $Global:Error | Should -Match 'Execution Timeout Expired'
    }

    It 'should support transactions' {
        $conn = Connect-YDatabase -SqlServerName $sqlServerName -DatabaseName 'master'
        $transaction = $conn.BeginTransaction()
        try
        {
            Invoke-YDbCommand -Connection $conn -Text 'create table [RolledBackTable] (id int)' -Transaction $transaction
            $transaction.Rollback()
        }
        finally
        {
            $conn.Close()
        }
        Invoke-YDbCommand -Connection $masterConn -Text 'select * from sys.tables where name=''RolledBackTable''' |
            Should -BeNullOrEmpty
    }

    It 'should support piping queries' {
        $results = 'select 1','select 2' | Invoke-YDbCommand -Connection $masterConn -AsScalar
        $results | Should -HaveCount 2
        $results[0] | Should -Be 1
        $results[1] | Should -Be 2
    }
}

$masterConn.Close()
