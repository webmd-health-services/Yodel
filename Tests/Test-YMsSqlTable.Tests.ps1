
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
    $script:schemaName = 'test-ymssqltable'
}

Describe 'Test-YMsSqlTable' {
    BeforeAll {
        GivenMSSqlSchema $script:schemaName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
    }

    It 'tests table that exists' {
        GivenMSSqlTable 'test-ymssqltable_1' -Column @('id int not null') -InSchema $script:schemaName
        $result = Test-YMsSqlTable -Connection $script:conn -SchemaName $script:schemaName -Name 'test-ymssqltable_1'
        $result | Should -BeTrue
        $result | Should -HaveCount 1
        $result | Should -BeOfType ([bool])
    }

    It 'tests table that does not exist' {
        $result = Test-YMsSqlTable -Connection $script:conn -Name 'test-ymssqltable_2'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passes thru table' {
        GivenMSSqlTable 'test-ymssqltable_4' -Column @('id int not null')
        $result = Test-YMsSqlTable -Connection $script:conn -Name 'test-ymssqltable_4' -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Not -BeOfType ([bool])
        $result.name | Should -Be 'test-ymssqltable_4'
    }
}
