
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
    $script:schemaName = 'test-ymssqlschema'
}

Describe 'Test-YMsSqlSchema' {
    BeforeAll {
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
    }

    It 'tests schema that exists' {
        GivenMSSqlSchema 'test-ymssqlschema_1'
        $result = Test-YMsSqlSchema -Connection $script:conn -Name 'test-ymssqlschema_1'
        $result | Should -BeTrue
        $result | Should -HaveCount 1
        $result | Should -BeOfType ([bool])
    }

    It 'tests schema that does not exist' {
        $result = Test-YMsSqlSchema -Connection $script:conn -Name 'test-ymssqlschema_2'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveCount 1
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passes thru schema' {
        GivenMSSqlSchema 'test-ymssqlschema_3'
        $result = Test-YMsSqlSchema -Connection $script:conn -Name 'test-ymssqlschema_3' -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Not -BeOfType ([bool])
        $result.name | Should -Be 'test-ymssqlschema_3'
    }
}
