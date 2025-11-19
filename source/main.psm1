##Module InfinityMake.Main
##Import InfinityMake.Log
##Import InfinityMake.Solution
##Import InfinityMake.Builder

function Invoke-Main([string[]]$ArgumentList) {
    if($ArgumentList.Contains('-d') -or $ArgumentList.Contains('--debug')){
        Set-LogMode LogDebug
    }
    $Solution = Get-SolutionFormFile '.\test_solution.ps1'
    Write-Log LogDebug ($Solution | ConvertTo-Json -Depth 10)
    Build-Solution $Solution
    return 0
}