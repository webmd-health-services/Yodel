
function Invoke-YDbCommand
{
    <#
    .SYNOPSIS
    Uses ADO.NET to execute a database command.

    .DESCRIPTION
    `Invoke-YDbCommand` executes a command against a database and returns a generic object for each row in the result set. Each object has a property for each column. If a column doesn't have a name, a generic `ColumnX` name is assigned, where `X` starts at 0 and increases by one for each nameless column.
    
    Pass the connection to the database to the `Connection` parameter. (Use the `Connect-YDatabase` function to create a connection.) Pass the command to run to the `Text` parameter. You may also pipe commands to `Invoke-YDbCommand`. If your command should be part of a transaction, pass the transaction to the `Transaction` parameter.

    If your command returns a single value, use the `-AsScalar` switch.

    If your command returns no results, use the `-NonQuery` switch. If your command affects any rows, the number of rows affected will be returned.

    To run a parameterized command, use `@name` parameters in your command and pass the values of those parameters in a hashtable to the `Parameter` parameter, e.g. `@{ '@name' = 'the_name' }`.

    To execute a stored procedure, set the `Text` parameter to the name of the stored procedure, set the `Type` parameter to `[Data.CommandType]::StoredProcedure`, and pass the procedure's parameters to the `Parameter` parameter (a hashtable of parameter names and values).

    Commands will time out after 30 seconds (the default .NET timeout). If you have a query that runs longer, pass the number of seconds to wait to the `Timeout` parameter. 

    Command timings are output to the verbose stream, including the text of the command. Command parameters are not output. If you want to suppress sensitive commands from being output, set the `Verbose` parameter to `$false`, e.g. `-Verbose:$false`.

    Failed queries do not cause a terminating error. If you want your script to stop if your query fails, set the `ErrorAction` parameter to `Stop`, e.g. `-ErrorAction Stop`.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'select * from MyTable'

    Demonstrates how to select rows from a table.

    .EXAMPLE
    'select 1','select 2' | Invoke-YDbCommand -Connection $conn

    Demonstrates that you can pipe commands to `Invoke-YDbCommand`.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'select count(*) from MyTable' -AsScalar

    Demonstrates how to return a scalar value.  If the command returns multiple rows/columns, returns the first row's first column's value.

    .EXAMPLE
    $rowsDeleted = Invoke-YDbCommand -Connection $conn -Text 'delete from dbo.Example' -NonQuery

    Demonstrates how to execute a command that doesn't return a value.  If your command updates/deletes rows, the number of rows affected is returned.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'insert into MyTable (Two,Three) values @Column2, @Column3' -Parameter @{ '@Column2' = 'Value2'; '@Column3' = 'Value3' } -NonQuery

    Demonstrates how to use parameterized queries.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'sp_addrolemember -CommandType [Data.CommandType]::StoredProcedure -Parameter @{ '@rolename = 'db_owner'; '@membername' = 'myuser'; }

    Demonstrates how to execute a stored procedure, including how to pass its parameters using the `Parameter` parameter.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'create login [yodeltest] with password ''P@$$w0rd''' -Verbose:$false

    Demonstrates how to prevent command timings for sensitive queries from being written to the verbose stream.

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'select * from a_really_involved_join_that_takes_a_long_time' -Timeout 120

    Demonstrates how to set the command timeout for commands that take longer than .NET's default timeout (30 seconds).

    .EXAMPLE
    Invoke-YDbCommand -Connection $conn -Text 'create table my_table (id int)' -Transaction $transaction

    Demonstrates that you can make the command part of a transaction by passing the transaction to the `Transaction` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='ExecuteReader')]
    param(
        [Parameter(Mandatory,Position=0)]
        # The connection to use.
        [Data.Common.DbConnection]$Connection,

        [Parameter(Mandatory,Position=1,ValueFromPipeline)]
        # The command to run/execute.
        [String]$Text,

        # The type of command being run. The default is `Text` for a SQL query.
        [Data.CommandType]$Type = [Data.CommandType]::Text,

        # The time (in seconds) to wait for a command to execute. The default is the .NET default, which is 30 seconds.
        [int]$Timeout,

        [Parameter(Position=2)]
        # Any parameters used in the command.
        [hashtable]$Parameter,
        
        [Parameter(Mandatory,ParameterSetName='ExecuteScalar')]
        # Return the result as a single value instead of a row.  If the command returns multiple rows/columns, the value of the first row's first column is returned.
        [switch]$AsScalar,
        
        [Parameter(Mandatory,ParameterSetName='ExecuteNonQuery')]
        # Executes a command that doesn't return any records.  For updates/deletes, the number of rows affected will be returned unless the NOCOUNT options is used.
        [switch]$NonQuery,

        # Any transaction the command should be part of.
        [Data.Common.DbTransaction]$Transaction
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $cmd = $Connection.CreateCommand()
        $cmd.CommandText = $Text
        $cmd.CommandTimeout = $Timeout
        $cmd.CommandType = $Type

        if( $Transaction )
        {
            $cmd.Transaction = $Transaction
        }

        if( $Parameter )
        {
            foreach( $name in $Parameter.Keys )
            {
                $value = $Parameter[$name]
                if( -not $name.StartsWith( '@' ) )
                {
                    $name = '@{0}' -f $name
                }
                [void]$cmd.Parameters.AddWithValue( $name, $value )
            }
        }

        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        try
        {
            if( $pscmdlet.ParameterSetName -like 'ExecuteNonQuery*' )
            {
                $rowsAffected = $cmd.ExecuteNonQuery()
                if( $rowsAffected -ge 0 )
                {
                    $rowsAffected
                }
            }
            elseif( $pscmdlet.ParameterSetName -like 'ExecuteScalar*' )
            {
                $cmd.ExecuteScalar()
            }
            else
            {
                $cmdReader = $cmd.ExecuteReader()
                try
                {
                    if( $cmdReader.HasRows )
                    {                
                        while( $cmdReader.Read() )
                        {
                            $row = @{ }
                            for ($i= 0; $i -lt $cmdReader.FieldCount; $i++) 
                            { 
                                $name = $cmdReader.GetName( $i )
                                if( -not $name )
                                {
                                    $name = 'Column{0}' -f $i
                                }
                                $value = $cmdReader.GetValue($i)
                                if( $cmdReader.IsDBNull($i) )
                                {
                                    $value = $null
                                }
                                $row[$name] = $value
                            }
                            New-Object 'PsObject' -Property $row
                        }
                    }
                }
                finally
                {
                    $cmdReader.Close()
                }
            }
        }
        catch
        {
            # SQL Server exceptions can be brutally nested.
            $ex = $_.Exception
            while( $ex.InnerException )
            {
                $ex = $ex.InnerException
            }

            $errorMsg = '{0}{1}{2}' -f $_.Exception.Message,[Environment]::NewLine,$Text
            Write-Error -Message $errorMsg -Exception $ex -ErrorAction $ErrorActionPreference
        }
        finally
        {
            $cmd.Dispose()

            $stopwatch.Stop()

            # Only calculate and output timings if verbose output is enabled. We don't even call Write-Verbose because 
            # some queries could have sensitive information in them, and in order to prevent them from being visible, the
            # user will add `-Verbose:$false` when calling this function. I'm being extra cautious here so there is no way
            # for someone to intercept sensitive queries.
            if( (Write-Verbose 'Active' 4>&1) )
            {
                $duration = $stopwatch.Elapsed
                if( $duration.TotalHours -ge 1 )
                {
                    $durationDesc = '{0,2}h {1,3}m ' -f [int]$duration.TotalHours,$duration.Minutes
                }
                elseif( $duration.TotalMinutes -ge 1 )
                {
                    $durationDesc = '{0,2}m {1,3}s ' -f [int]$duration.TotalMinutes,$duration.Seconds
                }
                elseif( $duration.TotalSeconds -ge 1 )
                {
                    $durationDesc = '{0,2}s {1,3}ms' -f [int]$duration.TotalSeconds,$duration.Milliseconds
                }
                else
                {
                    $durationDesc = '{0,7}ms' -f [int]$duration.TotalMilliseconds
                }

                $lines = $Text -split "\r?\n"
                Write-Verbose -Message ('{0}  {1}' -f $durationDesc, ($lines | Select-Object -First 1))
                foreach( $line in ($lines | Select-Object -Skip 1))
                {
                    Write-Verbose -Message ('{0}  {1}' -f (' ' * $durationDesc.Length), $line)
                }
            }
        }
    }
}
