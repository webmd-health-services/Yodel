
function Invoke-YSqlServerCommand
{
    <#
    .SYNOPSIS
    Uses ADO.NET to execute a query in a SQL Server database.

    .DESCRIPTION
    `Invoke-YSqlServerCommand` executes a SQL query against a SQL Server database. The function opens a connection to SQL Server, executes the query, then closes the connection. Pass the name of the SQL Server (hostname and instance name) to the `SqlServerName` parameter. Pass the database name to the `DatabaseName` parameter.  By default, the query is run as the current user. To run as a custom user, pass the user's credentials to the `Credential` parameter. 
    
    Pass the query to run to the `Text` parameter. You may also pipe queries to `Invoke-YSqlServerCommand`. Piped queries are all run using the same connection. 
    
    The function returns a generic object for each row in the result set. Each object has a property for each column. If a column doesn't have a name, a generic `ColumnX` name is assigned, where `X` starts at 0 and increases by one for each nameless column.

    If your query returns a single value, use the `-AsScalar` switch.

    If your query returns no results, use the `-NonQuery` switch. If your query affects any rows, the number of rows affected will be returned.

    To run a parameterized query, use `@name` parameters in your query and pass the values of those parameters in a hashtable to the `Parameter` parameter, e.g. `@{ '@name' = 'the_name' }`.

    To execute a stored procedure, set the `Text` parameter to the name of the stored procedure, set the `Type` parameter to `[Data.CommandType]::StoredProcedure`, and pass the procedure's parameters to the `Parameter` parameter (a hashtable of parameter names and values).

    Queries will time out after 30 seconds (the default .NET timeout). If you have a query that runs longer, pass the number of seconds to wait to the `Timeout` parameter. 

    Query timings are output to the verbose stream, including the text of the query. If you want to suppress sensitive queries from being output, set the `Verbose` parameter to `$false`, e.g. `-Verbose:$false`.

    The `Invoke-YSqlServerCommand` function constructs a connection string for you based on the values of the `SqlServerName` and `DatabaseName` parameters. If you have custom properties you'd like added to the connection string, pass them to the `ConnectionString` parameter.

    Failed queries do not cause a terminating error. If you want your script to stop if your query fails, set the `ErrorAction` parameter to `Stop`, e.g. `-ErrorAction Stop`.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select * from MyTable'

    Demonstrates how to select rows from a table.

    .EXAMPLE
    'select 1','select 2' | Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master'

    Demonstrates that you can pipe commands to `Invoke-YSqlServerCommand`. All queries piped to `Invoke-YSqlServerCommand` are run using the same connection.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select count(*) from MyTable' -AsScalar

    Demonstrates how to return a scalar value.  If the command returns multiple rows/columns, returns the first row's first column's value.

    .EXAMPLE
    $rowsDeleted = Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'delete from dbo.Example' -NonQuery

    Demonstrates how to execute a command that doesn't return a value.  If your command updates/deletes rows, the number of rows affected is returned.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'insert into MyTable (Two,Three) values @Column2, @Column3' -Parameter @{ Column2 = 'Value2'; Column3 = 'Value3' } -NonQuery

    Demonstrates how to use parameterized queries.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'sp_addrolemember' -CommandType [Data.CommandType]::StoredProcedure -Parameter @{ '@rolename' = 'db_owner'; '@membername' = 'myuser'; }

    Demonstrates how to execute a stored procedure, including how to pass its parameters using the `Parameter` parameter.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'create login [yodeltest] with password ''P@$$w0rd''' -Verbose:$false

    Demonstrates how to prevent command timings for sensitive queries from being written to the verbose stream.

    .EXAMPLE
    Invoke-YSqlServerCommand -SqlServerName '.' -DatabaseName 'master' -Text 'select * from a_really_involved_join_that_takes_a_long_time' -Timeout 120

    Demonstrates how to set the command timeout for commands that take longer than .NET's default timeout (30 seconds).
    #>
    [CmdletBinding(DefaultParameterSetName='ExecuteReader')]
    param(
        [Parameter(Mandatory,Position=0)]
        # The SQL Server instance to connect to.
        [String]$SqlServerName,

        [Parameter(Mandatory,Position=1)]
        # The database to connect to.
        [String]$DatabaseName,

        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,

        # The connection string to use.
        [String]$ConnectionString,

        [Parameter(Mandatory,Position=2,ValueFromPipeline)]
        # The command to run/execute.
        [String]$Text,

        # Any parameters used in the command.
        [hashtable]$Parameter,
        
        [Parameter(Mandatory,ParameterSetName='ExecuteScalar')]
        # Return the result as a single value instead of a row.  If the command returns multiple rows/columns, the value of the first row's first column is returned.
        [switch]$AsScalar,
        
        [Parameter(Mandatory,ParameterSetName='ExecuteNonQuery')]
        # Executes a command that doesn't return any records.  For updates/deletes, the number of rows affected will be returned unless the NOCOUNT option is used.
        [switch]$NonQuery,

        # The time (in seconds) to wait for a command to execute. The default is .NET's default timeout, which is 30 seconds.
        [int]$Timeout,

        # The type of command being run. The default is Text, or a plain query.
        [Data.CommandType]$Type = [Data.CommandType]::Text
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $optionalParams = @{}
        if( $Credential )
        {
            $optionalParams['Credential'] = $Credential
        }

        if( $ConnectionString )
        {
            $optionalParams['ConnectionString'] = $ConnectionString
        }

        $connection = Connect-YDatabase -SqlServerName $SqlServerName -DatabaseName $DatabaseName @optionalParams

        $optionalParams = @{}

        if( $AsScalar )
        {
            $optionalParams['AsScalar'] = $true
        }

        if( $NonQuery )
        {
            $optionalParams['NonQuery'] = $true
        }

        if( $Timeout )
        {
            $optionalParams['Timeout'] = $Timeout
        }

        if( $Type )
        {
            $optionalParams['Type'] = $Type
        }

        if( $Parameter )
        {
            $optionalParams['Parameter'] = $Parameter
        }
    }

    process
    {
        $cmdFailed = $true
        try
        {
            Invoke-YDbCommand -Connection $Connection -Text $Text @optionalParams
            $cmdFailed = $false
        }
        finally
        {
            # Terminating errors stop the pipeline.
            if( $cmdFailed )
            {
                $connection.Close()
            }
        }
    }

    end
    {
        $connection.Close()
    }
}

