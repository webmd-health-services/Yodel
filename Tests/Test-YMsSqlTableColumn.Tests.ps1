
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
    $script:schemaName = 'test-ymssqltablecolumn'
}

Describe 'Test-YMsSqlTableColumn' {
    BeforeAll {
        GivenMSSqlSchema $script:schemaName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
    }

    It 'tests column that exists' {
        GivenMSSqlTable 'test-ymssqltablecolumn_1' -Column @('id int not null') -InSchema $script:schemaName
        $result = Test-YMsSqlTableColumn -Connection $script:conn `
                                         -SchemaName $script:schemaName `
                                         -TableName 'test-ymssqltablecolumn_1' `
                                         -Name 'id'
        $result | Should -BeTrue
        $result | Should -HaveCount 1
    }

    It 'tests column that does not exist' {
        GivenMSSqlTable 'test-ymssqltablecolumn_2' -Column @('id3 int not null')
        $result = Test-YMsSqlTableColumn -Connection $script:conn -TableName 'test-ymssqltablecolumn_2' -Name 'id'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result | Should -BeFalse
    }

    It 'does not validate table exists' {
        $result = Test-YMsSqlTableColumn -Connection $script:conn `
                                         -TableName 'test-ymssqltablecolumn_3' `
                                         -Name 'id5'
        $result | Should -BeFalse
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passes thru column' {
        GivenMSSqlTable 'test-ymssqltablecolumn_4' -Column @('id int not null') -InSchema $script:schemaName
        $result = Test-YMsSqlTableColumn -Connection $script:conn `
                                         -SchemaName $script:schemaName `
                                         -TableName 'test-ymssqltablecolumn_4' `
                                         -Name 'id' `
                                         -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Not -BeOfType ([bool])
        $result.name | Should -Be 'id'
    }
}
