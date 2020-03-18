# Yodel

A PowerShell module for querying databases using the native .NET ADO.NET data access framework. 

# System Requirements

* PowerShell 5.1+ (Desktop or Core Editions)


# Installing

To make it available on an entire machine:

```powershell
Install-Module -Name 'Yodel'
```

To make it available just to you:

```powershell
Install-Module -Name 'Yodel' -Scope CurrentUser
```

To save it as a standalone module:

```powershell
Save-Module -Name 'Yodel' -Path '.'
```


# Usage

## SQL Server

The simplest command to use is `Invoke-YSqlServerCommand`. It connects to a SQL Server instance and database, runs a query, and closes the connection. Pass the name of the SQL Server instance to the `SqlServerName` parameter (`.` or the machine name for the default instance, `HOSTNAME\INSTANCE` for a named instance), the name of the database to the `Database` parameter, and the query to the `Text` parameter:

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select 1 First, 2, 3'

First Column0 Column1
----- ------- -------
    1       2       3
```

You'll get an object back for each row returned. Each object will have properties for each column. If a column doesn't have a name, Yodel will use a generic `ColumnX` name, where X is an incrementing number.

If you have a query that returns a single value, use the `-AsScalar` switch:

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select 1' -AsScalar
1
```

If your query doesn't return any results, use the `-NonQuery` switch. It will return the number of rows inserted/deleted (if any).

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'insert into example (id) values (1),(2),(3),(4)'
4
```

## Querying Other Databases

If you need to connect to another database, or need to use the same connection to run multiple queries, use `Connect-YDatabase` to connect to a database and `Invoke-YDbCommand` to run your queries/commands.

`Connect-YDatabase` takes a `System.Data.Common.DbProviderFactory` instance and uses that object to create the connection and connection string. .NET has built-in providers for SQL Server (shown below), Oracle, ODBC, and OLE providers (see example further below).

```powershell
$connection = Connect-YDatabase -Provider ([Data.SqlClient.SqlProviderFactory]::Instance) `
                                -ConnectionString 'some connection string'
try
{
    Invoke-YDbCommand -Connection $connection
}
finally
{
    # Don't forget to close the connection!
    $connection.Close()
}
```

The `Invoke-YDbCommand` takes in a generic ADO.NET connection (a class that inherits from `System.Data.Common.DbConnection`). It calls `CreateCommand()` on the connection. So, you can create your own connection and pass it to `Invoke-YDbCommand`:

```powershell
$connection = New-Object 'Data.SqlClient.SqlConnection'
$connection.ConnectionString = 'some connection string'
# Do some custom configuration on the connection.
$connection.Open()

try
{
    Invoke-YDbCommand -Connection $connection -Text 'select 1'
}
finally
{
    # Don't forget to close the connection!
    $connection.Close()
}
```


# Examples

## SQL Server: Read Rows

The fastest way to query a SQL Server database is to use the `Invoke-YSqlServerCommand` function:

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select * from sys.object'
                                                                                                                                                                                  
type principal_id is_published name                                         type_desc            schema_id is_ms_shipped parent_object_id is_schema_published modify_date         
---- ------------ ------------ ----                                         ---------            --------- ------------- ---------------- ------------------- -----------         
S                        False sysrscols                                    SYSTEM_TABLE                 4          True                0               False 8/22/2017 7:38:02 PM
S                        False sysrowsets                                   SYSTEM_TABLE                 4          True                0               False 8/22/2017 7:38:03 PM
S                        False sysclones                                    SYSTEM_TABLE                 4          True                0               False 8/22/2017 7:38:03 PM
S                        False sysallocunits                                SYSTEM_TABLE                 4          True                0               False 8/22/2017 7:38:02 PM
S                        False sysfiles1                                    SYSTEM_TABLE                 4          True                0               False 4/8/2003 9:13:37 AM 
```

The above example will connect to the master database in the local, default intance of SQL Server as the current user, and run the query `select 1` using integrated authentication. You'll get back an object for each row returned. Each object will have properties that match the column names in the result set. (If a column is missing a name, `Invoke-YSqlServerCommand` will create a generic `ColumnX` name for you, where `X` is number that increments for each nameless column.)

## SQL Server: Run a Query That Returns a Single/Scalar Value

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select 1' -AsScalar
1
```

## SQL Server: Run a Query That Returns No Results

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'tempdb' -Text 'create table yodel (id int)' -NonQuery
> Invoke-YSqlServerCommand -SqlServerName '.' `
                           -DatabaseName 'tempdb' `
                           -Text 'insert into yodel (id) values (1),(2)' `
                           -NonQuery
2
> Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'tempdb' -Text 'delete from yodel' -NonQuery
2
```

## SQL Server: Parameterized Queries

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' `
                           -DatabaseName 'master' `
                           -Text 'select * from sys.system_views where name = @name' `
                           -Parameter @{ '@name' = 'views' }

has_unchecked_assembly_data is_tracked_by_cdc is_published modify_date          has_opaque_metadata has_replication_filter is_ms_shipped parent_object_id is_date_correlation_view principal_id
--------------------------- ----------------- ------------ -----------          ------------------- ---------------------- ------------- ---------------- ------------------------ ------------
                      False             False        False 8/22/2017 7:38:29 PM               False                  False          True                0                    False
                      False             False        False 8/22/2017 7:38:07 PM               False                  False          True                0                    False
```

## SQL Server: Add Properties to Connection String

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' `
                           -DatabaseName 'master' `
                           -ConnectionString 'Application Name=Yodel' `
                           -Text 'select APP_NAME()' `
                           -AsScalar
Yodel
```

## SQL Server: Change Query Timeout

```powershell
> Invoke-YSqlServerCommand -SqlServerName '.' `
                           -DatabaseName 'master' `
                           -Text 'select 1' `
                           -Timeout 120
```

## SQL Server: Execute a Stored Procedure

```powershell
Invoke-YSqlServerCommand -SqlServerName '.' `
                         -DatabaseName 'master' `
                         -Text 'sp_addrolemember' `
                         -CommandType [Data.CommandType]::StoredProcedure `
                         -Parameter @{ '@rolename' = 'db_owner'; '@membername' = 'myuser'; }
```

## SQL Server: Run a Query as a Specific User

```powershell
$credential = Get-Credential
$username = Invoke-YSqlServerCommand -SqlServerName '.' `
                                     -DatabaseName 'master' `
                                     -Credential $credential `
                                     -Text 'select suser_name()' `
                                     -AsScalar
```

## Open a Connection to SQL Server

```powershell
$connection = Connect-YDatabase -SqlServerName '.' -DatabaseName 'master'
try
{
    # Run some queries
}
finally
{
    # Don't forget to do this!
    $connection.Close()
}
```

## Open a Connection to SQL Server As a Specific User

```powershell
$credential = Get-Credential
$connection = Connect-YDatabase -SqlServerName '.' -DatabaseName 'master' -Credential $credential
try
{
    # Returns the username of the user connected to SQL Server
    Invoke-YDbCommand -Connection $connection -Text 'select suser_name()' -AsScalar
}
finally
{
    # Don't forget to do this!
    $connection.Close()
}
```

## Open a Connection to SQL Server with Additional Connection String Properties

```powershell
$credential = Get-Credential
$connection = Connect-YDatabase -SqlServerName '.' `
                                -DatabaseName 'master' `
                                -ConnectionString 'Application Name=Yodel'
try
{
    # Should return "Yodel" (the app name set in our connection string).
    Invoke-YDbCommand -Connection $connection -Text 'select app_name()' -AsScalar
}
finally
{
    # Don't forget to do this!
    $connection.Close()
}
```

## Connecting to an ODBC Database

```powershell
$connection = Connect-YDatabase -ConnectionString 'connection string here' `
                                -Provider ([Data.Odbc.OdbcProviderFactory]::Instance)
try
{
    # Run some queries.
}
finally
{
    # Don't forget to close.
    $connection.Close()
}
```

## Connecting to an OLE Database

```powershell
$connection = Connect-YDatabase -ConnectionString 'connection string here' `
                                -Provider ([Data.OleDb.OleDbFactory]::Instance)
try
{
    # Run some queries.
}
finally
{
    # Don't forget to close.
    $connection.Close()
}
```

## Connecting to an Oracle Database

```powershell
$connection = Connect-YDatabase -ConnectionString 'connection string here' `
                                -Provider ([Data.OracleClient.OracleClientFactory]::Instance)
try
{
    # Run some queries.
}
finally
{
    # Don't forget to close.
    $connection.Close()
}
```

## Connecting to a Third-Party Database

The `Connect-YDatabase` functions' `Provider` parameter takes in any type that inherits from `System.Data.Common.DbFactoryProvider`. It calls the `CreateConnection()` method to create the connection and the `CreateConnectionStringBuilder()` method to create the connection string. So, if you can create or get an instance of that class, you can use Yodel to connect to that database.

```powershell
$myProvider = New-Object 'Yodel.CustomFactory'
$connection = Connect-YDatabase -ConnectionString 'connection string here' -Provider $myProvider
try
{
    # Run some queries
}
finally
{
    # Don't forget to close.
    $connection.Close()
}
```

## Read Rows

You can pass `Invoke-YDbCommand` *any* connection object that inherits from the ADO.NET `System.Data.Common.DbConnection` class, the common base class for all ADO.NET providers.

```powershell
> Invoke-YDbCommand -Connection $connection -Text 'select 1 First, 2, 3'

First Column0 Column1
----- ------- -------
    1       2       3
```

## Run a Command That Returns a Single/Scalar Value

```powershell
> Invoke-YDbCommand -Connection $connection -Text 'select 1' -AsScalar
1
```

## Run a Command That Returns No Results

```powershell
> Invoke-YDbCommand -Connection $connection -Text 'create table yodel (id int)' -NonQuery
> Invoke-YDbCommand -Connection $connection -Text 'insert into yodel (id) values (1)' -NonQuery
1
> Invoke-YDbCommand -Connection $connection -Text 'insert into yodel (id) values (2)' -NonQuery
1
> Invoke-YDbCommand -Connection $connection -Text 'delete from yodel' -NonQuery
2
```

## Parameterized Commands

```powershell
> Invoke-YDbCommand -Connection $connection -Text 'select 1 where 1=@value' -Parameter @{ '@value' = 1 }

Column0
-------
      1
```

## Change Command Timeout

```powershell
> Invoke-YDbCommand -Connection $connection -Text 'WAITFOR DELAY ''00:01:00''' -Timeout 61
```
This query takes 60 seconds to complete, so we set the command timeout to 61 seconds so the command doesn't fail.

## Execute a Stored Procedure

```powershell
Invoke-YDbCommand -Connection $connection `
                  -Text 'sp_addrolemember' `
                  -CommandType [Data.CommandType]::StoredProcedure `
                  -Parameter @{ '@rolename' = 'db_owner'; '@membername' = 'myuser'; }
```

## Use a Transaction

```powershell
$connection = Connect-YDatabase -SqlServerName '.' -DatabaseName 'master'
$transaction = $connection.BeginTransaction()
$failed = $true
try
{
    # Run your queries
    Invoke-YDbCommand -Connection $connection -Text 'select 1' -ErrorAction Stop
    $failed = $false
}
finally
{
    if( $failed )
    {
        $transaction.Rollback()
    }
    else
    {
        $transaction.Commit()
    }
    $connection.Close()
}
```

This example shows how to use a transaction so that multiple queries either succeed of they all succeed. Note that use of `-ErrorAction Stop` when calling `Invoke-YDbCommand`. Yodel doesn't throw a terminating exception when a query fails. So you have to do that so you can tell if a query failed.

# More Information

Detailed documentation is available via PowerShell's help system. Import the module and use the `Get-Help` cmdlet.

```powershell
Import-Module Yodel

> Get-Help Invoke-YSqlServerCommand
> Get-Help Connect-YDatabase
> Get-Help Invoke-YDbCommand
```

This example demonstrates how to get help for each of Yodel's commands.

