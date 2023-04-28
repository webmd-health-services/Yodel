
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:sqlServerName = Get-YTSqlServerName
    $script:masterConn = Connect-YDatabase -SqlServerName $script:sqlServerName -DatabaseName 'master'
}

AfterAll {
    $script:masterConn.Close()
}

Describe 'Invoke-YMSSqlCommand' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'returns objects for each row' {
        $row = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text 'select * from sys.system_views'
        $row | Should -Not -BeNullOrEmpty
        $row | Should -BeOfType ([PSObject])
        # Make sure objects get properties for each column.
        $row[0] | Get-Member 'name' | Should -Not -BeNullOrEmpty
        $row[0] | Get-Member 'object_id' | Should -Not -BeNullOrEmpty
    }

    It 'gives each unnamed column a name' {
        $row = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text 'select 1, 2, 3'
        $row | Should -Not -BeNullOrEmpty
        $row | Should -HaveCount 1
        $row.Column0 | Should -Be 1
        $row.Column1 | Should -Be 2
        $row.Column2 | Should -Be 3
    }

    It 'executes scalar' {
        $val = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text 'select 1' -AsScalar
        $val | Should -Be 1
    }

    It 'executes non query that affects no rows' {
        $value = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text 'select * from sys.system_views' -NonQuery
        $value | Should -BeNullOrEmpty
    }

    It 'executes parameterized queries' {
        $value = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text 'select * from [sys].[system_views] where name = @view_name' -Parameter @{ 'view_name' = 'system_views'; }
        $value | Should -Not -BeNullOrEmpty
        $value | Should -HaveCount 1
        $value.name | Should -Be 'system_views'
    }

    It 'executes non query that effects rows' {
        $cmd = 'if not exists (select * from sys.tables where name = ''YodelTable'') create table [YodelTable] (id int not null identity, name nvarchar not null)'
        Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text $cmd -NonQuery |
            Should -BeNullOrEmpty
        for( $idx = 0; $idx -lt 5; ++$idx )
        {
            $cmd = 'insert into YodelTable (name) values (''{0}'')' -f $idx
            Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -Text $cmd -NonQuery |
                Should -Be 1
        }

        $rowsAffected = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                                 -DatabaseName 'master' `
                                                 -Text 'delete from YodelTable' `
                                                 -NonQuery
        $rowsAffected | Should -Be 5
    }

    It 'executes sprocs' {
        $table =
            Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                     -DatabaseName 'master' `
                                     -Text 'select * from sys.tables' |
            Select-Object -First 1
        $result = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                           -DatabaseName 'master' `
                                           -Text 'sp_tables' `
                                           -Parameter @{ '@table_name' = $table.name } `
                                           -Type ([Data.CommandType]::StoredProcedure)
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result.TABLE_NAME | Should -Be $table.name
    }

    It 'writes query and query timings to the verbose stream' {
        $msg = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                        -DatabaseName 'master' `
                                        -Text ('WAITFOR{0}DELAY{0}''00:00:01''' -f [Environment]::NewLine) `
                                        -NonQuery `
                                        -Verbose 4>&1
        $msg | Write-Verbose  # In case you want to see them in the console.
        $msg | Should -HaveCount 3
        $msg[0] | Should -Match ' 1s +\d+ms  WAITFOR'
        $msg[1] | Should -Be '           DELAY'
        $msg[2] | Should -Be '           ''00:00:01'''
    }

    It 'does not call write verbose if verbose is off' {
        $VerbosePreference = 'Continue'
        $msg = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                        -DatabaseName 'master' `
                                        -Text 'WAITFOR DELAY ''00:00:00.001''' `
                                        -NonQuery `
                                        -Verbose:$false 4>&1
        $msg | Write-Verbose
        $msg | Should -BeNullOrEmpty
    }

    It 'can customize command timeout' {
        $Global:Error.Clear()
        Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                 -DatabaseName 'master' `
                                 -Text 'WAITFOR DELAY ''00:00:02''' `
                                 -Timeout 1 `
                                 -ErrorAction SilentlyContinue
        $Global:Error | Should -HaveCount 2
        $Global:Error | Should -Match 'timeout expired'
    }

    It 'respects error action argument' {
        $failed = $false
        try
        {
            Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                     -DatabaseName 'master' `
                                     -Text 'WAITFOR DELAY ''00:00:05''' `
                                     -Timeout 2 `
                                     -ErrorAction Stop
        }
        catch
        {
            $failed = $true
        }
        $failed | Should -BeTrue
        $Global:Error | Should -HaveCount 2
    }

    It 'receives queries from the pipeline' {
        $results =
            'select 1','select 2' |
            Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName -DatabaseName 'master' -AsScalar
        $results | Should -HaveCount 2
        $results[0] | Should -Be 1
        $results[1] | Should -Be 2
    }

    It 'can use custom connection string' {
        $connString = 'Server=example.com;Database=example.com;Application Name=Yodel'
        $result = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                           -DatabaseName 'master' `
                                           -ConnectionString $connString `
                                           -Text 'select APP_NAME()' `
                                           -AsScalar
        $result | Should -Be 'Yodel'
    }

    It 'can login with a credential' {
        $credential = GivenTestUser -SqlServerName $script:sqlServerName
        $result = Invoke-YMSSqlCommand -SqlServerName $script:sqlServerName `
                                           -DatabaseName 'master' `
                                           -Text 'select suser_name()' `
                                           -Credential (Get-YTUserCredential) `
                                           -AsScalar
        $result | Should -Be $credential.UserName
    }

    It 'can use someone else''s connection' {
        Invoke-YMSSqlCommand -Connection $script:masterConn -Text 'select db_name()' -AsScalar | Should -Be 'master'
        # Run twice to make sure our connection isn't closed/disposed.
        Invoke-YMSSqlCommand -Connection $script:masterConn -Text 'select db_name()' -AsScalar | Should -Be 'master'
        $Global:Error | Should -BeNullOrEmpty
    }
}
