
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot

enum Yodel_MsSql_QueryKeyword
{
    Default = 1
}

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = & {
    Join-Path -Path $script:moduleRoot -ChildPath 'Functions\*.ps1'
    Join-Path -Path $script:moduleRoot -ChildPath 'Functions\MsSql\*.ps1'
}
foreach( $functionPath in (Get-Item $functionsPath) )
{
    if ( -not (Test-Path -Path $functionPath))
    {
        continue
    }


    . (Get-Item -Path $functionPath).FullName
}
