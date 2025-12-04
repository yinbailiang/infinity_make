##Module Log.Test
##Import InfinityMake.Tools.Log

$TestLogServer = [LogServer]::new([LogType]::LogDebug)

$Loger = [LogClient]::new([LogType]::LogInfo)

$Loger.Write('Test1')
$Loger.OpenIndentationField{
    'Test2'
    'Test-----' + [System.Environment]::NewLine
    '-----3'
}
$Loger.Write('Test-----' + [System.Environment]::NewLine + '-----4')