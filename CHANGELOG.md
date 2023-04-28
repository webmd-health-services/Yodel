<!-- markdownlint-disable MD012 no-multiple-blanks -->

# Yodel Changelog

## 1.1.0

> Released 1 May 2023

### Added

* `Connection` parameter to `Invoke-YSqlServerCommand`.

### Changed

* The `Invoke-YSqlServerCommand` was renamed to `Invoke-MSSqlCommand`. Please update usages. The old name remains, but
you'll get a warning if you use it.

### Deprecated

* The `Invoke-YSqlServerCommand` function. Replace with `Invoke-MSSqlCommand`. Functionality not affectd, just the
name.


## 1.0.0

> Released 18 Mar 2020

* Created Connect-YDatabase function for connecting to an ADO.NET data source, like a SQL Server database.
* Created Invoke-YDbCommand function for executing an ADO.NET command, like a SQL query or stored procedure.
* Created Invoke-YSqlServerCommand function for executing commands against a SQL Server database.
