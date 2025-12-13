##Module InfinityMake.Main
##Import InfinityMake.Tools
##Import InfinityMake.Core
function Invoke-Main([string[]]$ArgumentList) {
    $Loger = [LogClient]::new($Script:DefaultLogServer)
}

Invoke-Main $args