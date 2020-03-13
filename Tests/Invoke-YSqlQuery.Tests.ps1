
$script:sqlServerName = 
    Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Server.txt' -Resolve) |
    Select-Object -First 1

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

Describe 'Invoke-YSqlQuery' {
    foreach( $context in @( 'with connection string','with server and database parameter' ) )
    {
        $supportsCredential = $false
        if( $context -eq 'with connection string' )
        {
            $param = @{
                        'ConnectionString' = 'Server={0};Database=Yodel;Integrated Security=True;' -f $script:sqlServerName
                    }
        }
        else
        {
            $supportsCredential = $true
            $param = @{
                        SqlServerName = $script:sqlServerName
                        Database = 'Yodel'
                    }
        }

        Context $context {
            BeforeAll {
                Invoke-YSqlQuery -SqlServerName $sqlServerName -Database 'master' -Query 'create database Yodel' -NonQuery | Out-Null
                Invoke-YSqlQuery @param -Query 'CREATE TABLE TestTable(ValueOne INT NULL)' -NonQuery | Out-Null
                Invoke-YSqlQuery @param -Query 'INSERT TestTable(ValueOne) VALUES(2)' -NonQuery | Out-Null
            }

            AfterAll {
                Invoke-YSqlQuery -SqlServerName $sqlServerName -Database 'master' -Query 'alter database [Yodel] set single_user with rollback immediate' -NonQuery | Out-Null
                Invoke-YSqlQuery -SqlServerName $sqlServerName -Database 'master' -Query 'drop database [Yodel]' -NonQuery | Out-Null
            }

            It 'Should Return Dataset' {
                $row = Invoke-YSqlQuery @param -Query 'SELECT * FROM TestTable'
                $row | Should -Not -BeNullOrEmpty

            }

            It 'Should Return Scalar' {
                $val = Invoke-YSqlQuery @param -Query 'SELECT TOP 1 ValueOne FROM TestTable' -AsScalar
                $val | Should -Be 2
            }

            It 'Should Return Nothing If No Rows Affected' {
                $value = Invoke-YSqlQuery @param -Query 'SELECT * FROM TestTable' -NonQuery
                $value | Should -BeNullOrEmpty
            }

            It 'Should Parameterize Query' {
                $value = Invoke-YSqlQuery @param -Query 'SELECT * FROM TestTable WHERE ValueOne = @ValueOne' -Parameter @{ ValueOne = 2; } -AsScalar
                $value | Should -Not -BeNullOrEmpty
                $value | Should -Be 2
            }

            It 'Should Execute Non Query' {
                $rowsAffected = Invoke-YSqlQuery @param -Query 'DELETE FROM TestTable' -NonQuery
                $rowsAffected | Should -Be 1
                $row = Invoke-YSqlQuery @param -Query 'SELECT * FROM TestTable'
                $row | Should -BeNullOrEmpty
            }
        }
    }
}
