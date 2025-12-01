##Module InfinityMake.Core.Solution

$SolutionTable = @{}

function Add-SolutionFormFile([string]$Name,[scriptblock]$Define) {
    $Solution = @{}

    $Define.Invoke()
    $SolutionTable[$Name] = $Solution
}