##Module InfinityMake.Main
##Import InfinityMake.Log
##Import InfinityMake.Solution
##Import InfinityMake.FileSystem

function Invoke-Main([string[]]$ArgumentList) {
    $BaseFileSystem = Build-BaseFileSystem
    $Loger = [LogClient]::new([ref]$CommonLogServer,[LogType]::LogInfo)
    $Loger.Write((Get-SolutionFormFile ".\test_solution.ps1" | ConvertTo-Json -Depth 10))
    return 0
}