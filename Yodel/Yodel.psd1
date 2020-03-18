#
# Module manifest for module '<$- moduleName '
#
# Generated on: Fri Mar 13 2020 15:34:51 GMT-0700 (Pacific Daylight Time)
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'Yodel.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'E15575BE-4C09-487D-B831-BCE4FCCFFBC4'

    # Author of this module
    Author = 'WebMD Health Services'

    # Company or vendor of this module
    CompanyName = 'WebMD Health Services'

    # If you want to support .NET Core, add 'Core' to this list.
    CompatiblePSEditions = @( 'Desktop', 'Core' )

    # Copyright statement for this module
    Copyright = '(c) 2020 WebMD Health Services. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A PowerShell module for querying SQL (and other) data sources using .NET''s native ADO.NET data access framework.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @( )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @( )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module. Only list public function here.
    FunctionsToExport = @(
                            'Connect-YDatabase',
                            'Invoke-YDbCommand',
                            'Invoke-YSqlServerCommand'
                         )

    # Cmdlets to export from this module. By default, you get a script module, so there are no cmdlets.
    # CmdletsToExport = @()

    # Variables to export from this module. Don't export variables except in RARE instances.
    VariablesToExport = @()

    # Aliases to export from this module. Don't create/export aliases. It can pollute your user's sessions.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'sql', 'query', 'ado', 'ado.net', 'database', 'db', 'data', 'entity', 'sqlserver', 'oracle', 'odbc', 'ole' )

            # A URL to the license for this module.
            LicenseUri = ' http://www.apache.org/licenses/LICENSE-2.0'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/webmd-health-services/Yodel'

            # A URL to an icon representing this module.
            # IconUri = ''

            # Any prerelease metadata.
            Prerelease = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
* Created Connect-YDatabase function for connecting to an ADO.NET data source, like a SQL Server database.
* Created Invoke-YDbCommand function for executing an ADO.NET command, like a SQL query or stored procedure.
'@
        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
