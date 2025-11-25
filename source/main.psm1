##Module InfinityMake.Main
##Import InfinityMake.Log
##Import InfinityMake.Solution
##Import InfinityMake.Builder
##Import InfinityMake.FileSystem

function Invoke-Main([string[]]$ArgumentList) {
    $FileSystem = Build-BaseFileSystem

    return 0
}