
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-YodelTest.ps1' -Resolve)

    $script:conn = Get-YTMSSqlConnection
    $script:connArg = @{ Connection = $script:conn }
}

Describe 'Test-YMsSqlExtendedProperty' {
    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
    }

    It 'tests extended property on schema' {
        $schemaName = 'test-ymssqlextendedproperty'
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test1'
        GivenMSSqlSchema $schemaName
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 1' -OnSchema $schemaName
        $result = Test-YMsSqlExtendedProperty @connArg -SchemaName $schemaName -Name $propName
        $result | Should -BeTrue
        $result | Should -BeOfType ([bool])
    }

    It 'tests non existent extended property on schema' {
        $schemaName = 'test-ymssqlextendedproperty'
        GivenMSSqlSchema $schemaName
        $result = Test-YMsSqlExtendedProperty @connArg -SchemaName $schemaName -Name 'yodel-does-not-exist'
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'tests extended property on non-existent schema' {
        $result = Test-YMsSqlExtendedProperty @connArg -SchemaName 'yodel-does-not-exist' -Name 'does not matter'
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'tests extended property on table' {
        $tableName = 'test-ymssqlextendedpropertytable_1'
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test3'
        GivenMSSqlTable $tableName 'id int not null'
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 2' -OnTable $tableName
        $result = Test-YMsSqlExtendedProperty @connArg -TableName $tableName -Name $propName
        $result | Should -BeTrue
        $result | Should -BeOfType ([bool])
    }

    It 'tests extended property on non-existent table' {
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test4'
        $result = Test-YMsSqlExtendedProperty @connArg -TableName 'yodel-does-not-exist' -Name $propName
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'tests non existent extended property on table' {
        $tableName = 'test-ymssqlextendedpropertytable_2'
        GivenMSSqlTable $tableName 'id int not null'
        $result = Test-YMsSqlExtendedProperty @connArg -TableName $tableName -Name 'yodel-does-not-exist'
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'tests extended property on table column' {
        $tableName = 'test-ymssqlextendedproperty_3'
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test5'
        GivenMSSqlTable $tableName 'id int not null'
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 3' -OnTable $tableName -OnColumn 'id'
        $result = Test-YMsSqlExtendedProperty @connArg -TableName $tableName -ColumnName 'id' -Name $propName
        $result | Should -BeTrue
        $result | Should -BeOfType ([bool])
    }

    It 'tests extended property on non existent table column' {
        $tableName = 'test-ymssqlextendedproperty_4'
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test6'
        GivenMSSqlTable $tableName 'id int not null'
        GivenMSSqlExtendedProperty $propName -WithValue 'from test 3' -OnTable $tableName -OnColumn 'id'
        $result = Test-YMsSqlExtendedProperty @connArg -TableName $tableName -ColumnName 'id2' -Name $propName
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'tests non-existent extended property on table column' {
        $tableName = 'test-ymssqlextendedproperty_5'
        $propName = 'Yodel_Test-YMsSqlExtendedProperty_Test7'
        GivenMSSqlTable $tableName 'id int not null'
        $result = Test-YMsSqlExtendedProperty -TableName $tableName `
                                              -ColumnName 'yodel-does-not-exist' `
                                              -Name $propName `
                                              @connArg
        $result | Should -BeFalse
        $result | Should -BeOfType ([bool])
        $Global:Error | Should -BeNullOrEmpty
    }
}
