##Module InfinityMake.Log

enum LogType{
    LogErr = 0
    LogWarn = 1
    LogInfo = 2
    LogDebug = 3
}

[LogType]$LogMode = [LogType]::LogInfo
[ref]$RefLogMode = [ref]::new($LogMode)
function Set-LogMode([LogType]$Mode) {
    $RefLogMode.Value = $Mode
}

$Loger = @{}
function Write-Log([LogType]$LogType, [string]$Text) {
    [Int32]$Index = $LogType
    if($Index -gt $RefLogMode.Value){
        return
    }
    Invoke-Command $Loger[$LogType] -ArgumentList $Text
}

$Loger[[LogType]::LogErr] = {
    param([string]$Text)
    Write-Host "[Err]$Text" -ForegroundColor Red
}
$Loger[[LogType]::LogWarn] = {
    param([string]$Text)
    Write-Host "[Warn]$Text" -ForegroundColor Yellow
}
$Loger[[LogType]::LogInfo] = {
    param([string]$Text)
    Write-Host "[Info]$Text"
}
$Loger[[LogType]::LogDebug] = {
    param([string]$Text)
    Write-Host "[Debug]$Text" -ForegroundColor Blue
}