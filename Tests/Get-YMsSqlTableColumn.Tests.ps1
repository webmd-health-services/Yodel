
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
    $script:schemaName = 'get-ymssqltablecolumn'
}

Describe 'Get-YMsSqlTableColumn' {
    BeforeAll {
        GivenMSSqlSchema $script:schemaName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
    }

    It 'gets columns' {
        GivenMSSqlTable 'get-ymssqltablecolumn_1' `
                        -Column @('id int not null', 'id2 nvarchar') `
                        -InSchema $script:schemaName
        $columns = Get-YMsSqlTableColumn -Connection $script:conn `
                                         -SchemaName $script:schemaName `
                                         -TableName 'get-ymssqltablecolumn_1'
        $columns | Should -Not -BeNullOrEmpty
        $columns | Should -HaveCount 2
        $columns[0].name | Should -Be 'id'
        $columns[1].name | Should -Be 'id2'
    }

    It 'gets a column' {
        GivenMSSqlTable 'get-ymssqltablecolumn_2' -Column @('id3 int not null', 'id4 nvarchar')
        $column = Get-YMSSqlTableColumn -Connection $script:conn -TableName 'get-ymssqltablecolumn_2' -Name 'id3'
        $column | Should -Not -BeNullOrEmpty
        $column | Should -HaveCount 1
        $column.name | Should -Be 'id3'
    }

    It 'validates table exists' {
        $result = Get-YMsSqlTableColumn -Connection $script:conn `
                                        -TableName 'get-ymssqltablecolumn_3' `
                                        -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -Match ([regex]::Escape('[dbo].[get-ymssqltablecolumn_3] does not exist'))
    }

    It 'validates column exists' {
        GivenMSSqlTable 'get-ymssqltablecolumn_4' -Column @('id5 int not null')
        $result = Get-YMsSqlTableColumn -Connection $script:conn `
                                        -TableName 'get-ymssqltablecolumn_4' `
                                        -Name 'id6' `
                                        -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Column \[id6\] does not exist'
    }

    It 'ignores errors' {
        GivenMSSqlTable 'get-ymssqltablecolumn_5' -Column @('id7 int not null')
        $result = Get-YMsSqlTableColumn -Connection $script:conn `
                                        -TableName 'get-ymssqltablecolumn_5' `
                                        -Name 'id8' `
                                        -ErrorAction Ignore
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }
}
