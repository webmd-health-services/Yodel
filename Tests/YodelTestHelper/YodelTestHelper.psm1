
function Get-YTSqlServerName
{
    Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Server.txt' -Resolve) |
        Select-Object -First 1

}