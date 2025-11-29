##Module InfinityMake.Main
##Import InfinityMake.Tools

function Invoke-Main([string[]]$ArgumentList) {
    $Loger = [LogClient]::new([LogType]::LogInfo)
    $Loger.Write("?????")
    Import-DynamicModule "language.c"
    
    return 0
}