##Module InfinityMake.Main
##Import InfinityMake.Tool.Log
##Import InfinityMake.Tool.DynamicModule
##Import InfinityMake.XXX

function Invoke-Main([string[]]$ArgumentList) {
    $Loger = [LogClient]::new([LogType]::LogInfo)
    $Loger.Write("?????")
    Import-DynamicModule "language.c"
    
    return 0
}