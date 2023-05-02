
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
}

Describe 'Get-ExtendedProperty' {
    BeforeEach {
    }

    AfterEach {
    }

    It 'gets extended property on schema' {
        $schemaName = 'get-ymssqlextendedproperty'
        $propName = 'Yodel_Get-ExtendedProperty_Test1'
        GivenMSSqlSchema $schemaName
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 1' -OnSchema $schemaName
        ThenMSSqlExtendedProperty $propName -OnSchema $schemaName -HasValue 'from test 1'
    }

    It 'gets extended property on table' {
        $tableName = 'get-extendedproptable'
        $propName = 'Yodel_Get-ExtendedProperty_Test2'
        GivenMSSqlTable $tableName 'id int not null'
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 2' -OnTable $tableName
        ThenMSSqlExtendedProperty $propName -OnTable $tableName -HasValue 'from test 2'
    }

    It 'gets extended property on table column' {
        $tableName = 'get-extendedproptable'
        $propName = 'Yodel_Get-ExtendedProperty_Test3'
        GivenMSSqlTable $tableName 'id int not null'
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 3' -OnTable $tableName -OnColumn 'id'
        ThenMSSqlExtendedProperty $propName -OnTable $tableName -OnColumn 'id' -HasValue 'from test 3'
    }
}
