<!-- markdownlint-disable MD012 no-multiple-blanks -->

# Yodel Changelog

## 1.1.0

### Added

Functions specific to Microsoft SQL Server:

* `ConvertTo-YMsSqlIdentifier` for converting a string to an identifer, quoted with square brackets.
* `Get-YMsSqlExtendedProperty` for getting extended properties.
* `Get-YMsSqlSchema` for getting metadata about a schema.
* `Get-YMsSqlTable` for getting metadata about a table.
* `Get-YMsSqlTableColumn` for getting metadata about a table.
* `Initialize-YMsSqlDatabase` for creating a database.
* `Initialze-YMsSqlSchema` for creating a schema.
* `Invoke-YMsSqlCommand` for running queries and commands.
* `Remove-YMsSqlTable` for dropping a table.
* `Set-YMsSqlExtendedProperty` for adding/updating extended properties.
* `Test-YMsSqlExtendedProperty` for testing if an extended property exists.
* `Test-YMsSqlSchema` for testing if a schema exists.
* `Test-YMsSqlTable` for testing if a table exists.
* `Test-YMsSqlTableColumn` for testing if a table column exists.

### Deprecated

* The `Invoke-YSqlServerCommand` function. Replaced with `Invoke-YMsSqlCommand`.


## 1.0.0

> Released 18 Mar 2020

* Created Connect-YDatabase function for connecting to an ADO.NET data source, like a SQL Server database.
* Created Invoke-YDbCommand function for executing an ADO.NET command, like a SQL query or stored procedure.
* Created Invoke-YSqlServerCommand function for executing commands against a SQL Server database.
