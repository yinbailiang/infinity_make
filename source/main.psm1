##Module InfinityMake.Main
##Import InfinityMake.Tools
##Import InfinityMake.Core

function Invoke-Main([string[]]$ArgumentList) {
    $Loger = [LogClient]::new([LogType]::LogDebug)

    $Loger.Write('DynamicModule')
    $Loger.OpenIndentationField{
        Get-DynamicModule
    }

    . './infinity_solution.ps1'

    $Loger.Write('Solution')
    $Loger.OpenIndentationField{
        ($SolutionTable | ConvertTo-Json -Depth 5)
    }
    return 0
}