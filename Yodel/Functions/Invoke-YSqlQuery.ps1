
function Invoke-YSqlQuery
{
    <#
    .SYNOPSIS
    Uses ADO.NET to execute a SQL query.

    .DESCRIPTION
    `Invoke-YSqlQuery` executes a query and returns generic objects for each row returned. The objects have properties for each of the columns selected.

    If you want to return a single value, use the `AsScalar` switch.

    If you're executing a query that doesn't return any values, use the `NonQuery` switch, which returns the number of rows affected.  If your query updates/deletes rows, the number of rows affected is returned.

    .EXAMPLE
    Invoke-YSqlQuery -SqlServerName '.\SQL2017' -Database 'Yodel' -Query 'select * from rivet.Migrations'

    Demonstrates how to select rows from a table.

    .EXAMPLE
    Invoke-YSqlQuery -SqlServerName '.\SQL2017' -Database 'Yodel' -Query 'select count(*) from rivet.Migrations' -AsScalar

    Demonstrates how to return a scalar value.  If the query returns multiple rows/columns, returns the first row's first column's value.

    .EXAMPLE
    $rowsDeleted = Invoke-YSqlQuery -SqlServerName '.\SQL2017' -Database 'Yodel' -Query 'delete from dbo.Example' -NonQuery

    Demonstrates how to execute a query that doesn't return a value.  If your query updates/deletes rows, the number of rows affected is returned.

    .EXAMPLE
    Invoke-YSqlQuery -SqlServerName '.\SQL2017' -Database 'Yodel' -Query 'exec InsertRecord @Column2, @Column3' -Parameter @{ Column2 = 'Value2'; Column3 = 'Value3' }

    Demonstrates how to use parameterized queries.

    .EXAMPLE
    Invoke-YSqlQuery -ConnectionString 'Server=.\SQL2017;Database=Yodel;Integrated Security=True;' -Query 'select 1'

    Demonstrates how to execute a query using a connection string.
    #>
    [CmdletBinding(DefaultParameterSetName='AsReader')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='AsReaderWithConnectionString')]
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteScalarWithConnectionString')]
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteNonQueryWithConnectionString')]
        [string]
        # The connection string to use.
        $ConnectionString,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName='AsReader')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='ExecuteScalar')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='ExecuteNonQuery')]
        [Alias('ServerInstance')]
        [string]
        # The SQL Server instance to connect to.
        $SqlServerName,

        [Parameter(Mandatory=$true,Position=1,ParameterSetName='AsReader')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='ExecuteScalar')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='ExecuteNonQuery')]
        [string]
        # The database to connect to.
        $Database,

        [Parameter(Mandatory=$true,Position=2,ParameterSetName='AsReader')]
        [Parameter(Mandatory=$true,Position=2,ParameterSetName='ExecuteScalar')]
        [Parameter(Mandatory=$true,Position=2,ParameterSetName='ExecuteNonQuery')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='AsReaderWithConnectionString')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='ExecuteScalarWithConnectionString')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='ExecuteNonQueryWithConnectionString')]
        [string]
        # The query to run/execute.
        $Query,

        [Hashtable]
        # Any parameters used in the query.
        $Parameter,
        
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteScalar')]
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteScalarWithConnectionString')]
        [Switch]
        # Return the result as a single value instead of a row.  If the query returns multiple rows/columns, the value of the first row's first column is returned.
        $AsScalar,
        
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteNonQuery')]
        [Parameter(Mandatory=$true,ParameterSetName='ExecuteNonQueryWithConnectionString')]
        [Switch]
        # Executes a query that doesn't return any records.  For updates/deletes, the number of rows affected will be returned unless the NOCOUNT options is used.
        $NonQuery,

        [Parameter(ParameterSetName='AsReader')]
        [Parameter(ParameterSetName='ExecuteScalar')]
        [Parameter(ParameterSetName='ExecuteNonQuery')]
        [int]
        # The time (in seconds) to wait for a connection to open. The default is 10 seconds.
        $ConnectionTimeout = 10,

        [int]
        # The time (in seconds) to wait for a command to execute. The default is 30 seconds.
        $CommandTimeout = 30,

        [Parameter(ParameterSetName='AsReader')]
        [Parameter(ParameterSetName='ExecuteScalar')]
        [Parameter(ParameterSetName='ExecuteNonQuery')]
        [ValidateNotNullOrEmpty()]
        [PSCredential] 
        $Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $conn = New-Object 'Data.SqlClient.SqlConnection'

    if( $PSCmdlet.ParameterSetName -notlike '*WithConnectionString' )
    {
        if ($Credential)
        {
            $ConnectionString = 'Server={0};Database={1};Connection Timeout={2}' `
                                    -f $SqlServerName,$Database,$ConnectionTimeout

            # Make password on credentual read only
            $Credential.Password.MakeReadOnly()
            $conn.Credential = New-Object System.Data.SqlClient.SqlCredential `
                                                    -ArgumentList ($Credential.UserName, $Credential.Password)

        }
        else
        {
            $ConnectionString = 'Server={0};Database={1};Integrated Security=True;Connection Timeout={2}' `
                                    -f $SqlServerName,$Database,$ConnectionTimeout
        }
    }
    Write-Verbose ('Connection String: {0}' -f $ConnectionString)
    
    $conn.ConnectionString = $ConnectionString
    $conn.Open()
    
    $cmd = New-Object 'Data.SqlClient.SqlCommand' ($Query,$conn)
    $cmd.CommandTimeout = $CommandTimeout

    Write-Verbose ('Query: {0}' -f $Query)
    if( $Parameter )
    {
        $Parameter.Keys | ForEach-Object { 
            $name = $_
            $value = $Parameter[$name]
            if( -not $name.StartsWith( '@' ) )
            {
                $name = '@{0}' -f $name
            }
            Write-Verbose ('{0} = {1}' -f $name,$value)
            [void] $cmd.Parameters.AddWithValue( $name, $value )
        }
    }

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
        $errorMsg = '{0}{1}{2}' -f $_.Exception.Message,[Environment]::NewLine,$Query
        Write-Error -Message $errorMsg  
    }
    finally
    {
        $cmd.Dispose()
        $conn.Close()
    }
}
