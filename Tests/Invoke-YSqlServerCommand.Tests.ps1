
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

$sqlServerName = Get-YTSqlServerName
$masterConn = Connect-YDatabase -SqlServerName $sqlServerName -DatabaseName 'master'

function Init
{
}


Describe 'Invoke-YSqlServerCommand.when reading rows' {
    It 'should return objects for each row' {
        $row = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select * from sys.system_views'
        $row | Should -Not -BeNullOrEmpty
        $row | Should -BeOfType ([PSObject])
        # Make sure objects get properties for each column.
        $row[0] | Get-Member 'name' | Should -Not -BeNullOrEmpty
        $row[0] | Get-Member 'object_id' | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-YSqlServerCommand.when columns have no names' {
    It 'should user a filler name' {
        $row = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select 1, 2, 3'
        $row | Should -Not -BeNullOrEmpty
        $row | Should -HaveCount 1
        $row.Column0 | Should -Be 1
        $row.Column1 | Should -Be 2
        $row.Column2 | Should -Be 3
    }
}

Describe 'Invoke-YSqlServerCommand.when executing a scalar' {
    It 'should return single value' {
        $val = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select 1' -AsScalar
        $val | Should -Be 1
    }
}

Describe 'Invoke-YSqlServerCommand.when executing a non query that affects no rows' {
    It 'should return nothing' {
        $value = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select * from sys.system_views' -NonQuery
        $value | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-YSqlServerCommand.when using a parameterized query' {
    It 'should pass parameters to command' {
        $value = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select * from [sys].[system_views] where name = @view_name' -Parameter @{ 'view_name' = 'system_views'; }
        $value | Should -Not -BeNullOrEmpty
        $value | Should -HaveCount 1
        $value.name | Should -Be 'system_views'
    }
}

Describe 'Invoke-YSqlServerCommand.when executing a non query that affects rows' {
    It 'should return number of rows affected' {
        $cmd = 'if not exists (select * from sys.tables where name = ''YodelTable'') create table [YodelTable] (id int not null identity, name nvarchar not null)'
        Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text $cmd -NonQuery | Should -BeNullOrEmpty
        for( $idx = 0; $idx -lt 5; ++$idx )
        {
            $cmd = 'insert into YodelTable (name) values (''{0}'')' -f $idx
            Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text $cmd -NonQuery | Should -Be 1
        }

        $rowsAffected = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'delete from YodelTable' -NonQuery
        $rowsAffected | Should -Be 5
    }
}

Describe 'Invoke-YSqlServerCommand.when executing a stored procedure' {
    It 'should execute successfully' {
        $table = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select * from sys.tables' | Select-Object -First 1
        $result = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'sp_tables' -Parameter @{ '@table_name' = $table.name } -Type ([Data.CommandType]::StoredProcedure)
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result.TABLE_NAME | Should -Be $table.name
    }
}

Describe 'Invoke-YSqlServerCommand.when verbose messages are turned on' {
    It 'should output command timings' {
        $msg = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text ('WAITFOR{0}DELAY{0}''00:00:01''' -f [Environment]::NewLine) -NonQuery -Verbose 4>&1
        $msg | Write-Verbose  # In case you want to see them in the console.
        $msg | Should -HaveCount 3
        $msg[0] | Should -Match ' 1s +\d+ms  WAITFOR'
        $msg[1] | Should -Be '           DELAY'
        $msg[2] | Should -Be '           ''00:00:01'''
    } 
}

Describe 'Invoke-YSqlServerCommand.when verbose messages are off' {
    It 'should not even write messages' {
        $VerbosePreference = 'Continue'
        $msg = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'WAITFOR DELAY ''00:00:00.001''' -NonQuery -Verbose:$false 4>&1
        $msg | Write-Verbose
        $msg | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-YSqlServerCommand.when customizing command timeout' {
    It 'should fail if command is longer than the timeout' {
        $Global:Error.Clear()
        Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'WAITFOR DELAY ''00:00:02''' -Timeout 1 -ErrorAction SilentlyContinue
        $Global:Error | Should -HaveCount 2
        $Global:Error | Should -Match 'timeout expired'
    }
}

Describe 'Invoke-YSqlServerCommand.when user sets error action to stop' {
    It 'should still throw a terminating error' {
        $Global:Error.Clear()
        $failed = $false
        try
        {
            Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'WAITFOR DELAY ''00:00:02''' -Timeout 2 -ErrorAction Stop
        }
        catch
        {
            $failed = $true
        }
        $failed | Should -BeTrue
        $Global:Error | Should -HaveCount 2
    }
}

Describe 'Invoke-YSqlServerCommand.when piping queries' {
    It 'should should execute each' {
        $results = 'select 1','select 2' | Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -AsScalar
        $results | Should -HaveCount 2
        $results[0] | Should -Be 1
        $results[1] | Should -Be 2
    }
}

Describe 'Invoke-YSqlServerCommand.when passing connection string' {
    It 'should use values in connection string and override properties from function parameters' {
        $result = Invoke-YSqlServerCommand -SqlServerName $sqlServerName `
                                           -DatabaseName 'master' `
                                           -ConnectionString 'Server=example.com;Database=example.com;Application Name=Yodel' `
                                           -Text 'select APP_NAME()' `
                                           -AsScalar
        $result | Should -Be 'Yodel'
    }
}

Describe 'Invoke-YSqlServerCommand.when logging in as custom user' {
    It 'should run commands as that user' {
        Init
        $credential = GivenTestUser -SqlServerName $sqlServerName
        $result = Invoke-YSqlServerCommand -SqlServerName $sqlServerName -DatabaseName 'master' -Text 'select suser_name()' -Credential (Get-YTUserCredential) -AsScalar
        $result | Should -Be $credential.UserName
    }
}

$masterConn.Close()
