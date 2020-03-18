
function Connect-YDatabase
{
    <#
    .SYNOPSIS
    Opens an ADO.NET connection to a database.

    .DESCRIPTION
    The `Connect-YDatabase` function opens an ADO.NET (i.e. pure .NET) connection to a database. Pass the connection string to the `ConnectionString` parameter. Pass the provider to use to connect to the `Provider` parameter. This parameter should be an instance of a `Data.Common.DbProviderFactory` object. The .NET framework ships with several:

    * SQL Server: `Connect-YDatabase -Provider ([Data.SqlClient.SqlClientFactory]::Instance)`
    * ODBC: `Connect-YDatabase -Provider ([Data.Odbc.OdbcFactory]::Instance)`
    * OLE: `Connect-YDatabase -Provider ([Data.OleDb.OleDbFactory]::Instance)`
    * Entity Framework: `Connect-YDatabase -Provider ([Data.EntityClient.EntityProviderFactory]::Instance)`
    * Oracle: `Connect-YDatabase -Provider ([Data.OracleClient.OracleClientFactory]::Instance)`

    The function uses each provider to create a connection object, sets that connection's connection string, open the connection, and then returns the connection.

    The `Connect-YDatabase` also has a simplified parameter set to open a connection to SQL Server. Pass the SQL Server name (e.g. `HOST\INSTANCE`) to the `SqlServerName` parameter, the database name to the `DatabaseName` parameter, and any other connection properties to the `ConnectionString` property. The function will create a connection to the SQL Server database using integrated authentication. To connect as a specific user, pass that user's credentials to the `Credential` parameter. ADO.NET requires that the credential's password be in read-only mode, so `Connect-YDatabase` will call `$Credential.Password.MakeReadOnly()`.

    Returns a `Data.Common.DbConnection` object, the base class for all ADO.NET connections. You are responsible for closing the connection:

        $conn = Connect-YDatabase -SqlServerName '.' -DatabaseName 'master'
        try
        {
            # run some queries
        }
        finally
        {
            # YOU MUST DO THIS!
            $conn.Close()
        }

    .EXAMPLE
    Connect-YDatabase -SqlServerName '.' -DatabaseName 'master'

    Demonstrates how to connect to Microsoft SQL Server using integrated authentiction.

    .EXAMPLE
    Connect-YDatabase -SqlServerName '.' -DatabaseName 'master' -Credential $credential

    Demonstrates how to connect to Microsoft SQL Server as a specific user. The `$credential` parameter must be `PSCredential` object.

    .EXAMPLE
    Connect-YDatabase -SqlServerName '.' -DatabaseName 'master' -ConnectionString 'Application Name=Yodel;Workstation ID=SomeComputerName'

    Demonstrates how to supply additional connection string properties when using the SQL Server parameter set.

    .EXAMPLE
    Connect-YDatabase -Provider ([Data.Odbc.OdbcFactory]::Instance) -ConnectionString 'some connection string'

    Demonstrates how to connect to a database using ODBC.

    .EXAMPLE
    Connect-YDatabase -Provider ([Data.OleDb.OleDbFactory]::Instance) -ConnectionString 'some connection string'

    Demonstrates how to connect to a database using OLE.

    .EXAMPLE
    Connect-YDatabase -Provider ([Data.EntityClient.EntityProviderFactory]::Instance) -ConnectionString 'some connection string'

    Demonstrates how to connect to a database using the Entity Framework provider.

    .EXAMPLE
    Connect-YDatabase -Provider ([[Data.OracleClient.OracleClientFactory]::Instance) -ConnectionString 'some connection string'

    Demonstrates how to connect to a database using Oracle.
    #>
    [CmdletBinding()]
    [OutputType([Data.Common.DbConnection])]
    param(
        [Parameter(Mandatory,ParameterSetName='SqlServer')]
        [String]$SqlServerName,

        [Parameter(Mandatory,ParameterSetName='SqlServer')]
        [String]$DatabaseName,

        [Parameter(ParameterSetName='SqlServer')]
        [pscredential]$Credential,

        [Parameter(Mandatory,ParameterSetName='Generic')]
        [Data.Common.DbProviderFactory]$Provider,

        # The connection string to use.
        [String]$ConnectionString,

        # The connection timeout. By default, uses the .NET default of 30 seconds. If it takes longer than this number of seconds to connect, the function will fail.
        #
        # Setting this property adds a `Connection Timeout` property to the connection string if you're connecting to a SQL Server database (i.e. using the `SqlServerName` parameter). If you're connecting via ODBC, the `ConnectionTimeout` property is set. In all other cases, this parameter is ignored.
        #
        # If you get an error that `ConnectionTimeout` is a read-only property, you'll need to pass the timeout as a property in your connection string.
        [int]$ConnectionTimeout
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'SqlServer' )
    {
        $Provider = [Data.SqlClient.SqlClientFactory]::Instance
    }

    $connection = $Provider.CreateConnection()
    $connStringBuilder = $Provider.CreateConnectionStringBuilder()
    
    if( $ConnectionString )
    {
        # There's some weird PowerShell magic going on when setting the ConnectionString property, so directly call the setter function.
        $connStringBuilder.set_ConnectionString($ConnectionString)
    }

    if( $PSCmdlet.ParameterSetName -eq 'SqlServer' )
    {
        $connStringBuilder['Server'] = $SqlServerName
        $connStringBuilder['Database'] = $DatabaseName

        if( $Credential )
        {
            $Credential.Password.MakeReadOnly()
            $sqlCredential = [Data.SqlClient.SqlCredential]::new($Credential.UserName, $Credential.Password)
            $connection.Credential = $sqlCredential
        }
        else
        {
            $connStringBuilder['Integrated Security'] = 'True'
        }

        if( $ConnectionTimeout )
        {
            $connStringBuilder['Connection Timeout'] = $ConnectionTimeout
        }

        $ConnectionString = $connStringBuilder.ToString()
    }
    else
    {
        if( $ConnectionTimeout )
        {
            $connection.ConnectionTimeout = $ConnectionTimeout
        }
    }

    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    return $connection
}