# 根据参数执行脚本并利用调试信息映射错误信息
param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [Parameter(Mandatory=$false)]
    [string]$DebugInfoPath,
    [Parameter(Mandatory=$false)]
    [switch]$ReBuild
)
if($ReBuild){
    Write-Host "[InfinityDbg] 重新构建"
    & ./infinity_build.ps1 -ConfigPath ".\buildconfig.json"
    Write-Host "[InfinityDbg] 重新构建完成"
}

try {
    $DebugInfo = @{}
    if(-not $DebugInfoPath){
        $ScriptInfo = Get-Item -Path $ScriptPath
        $DebugInfoPath = Join-Path $ScriptInfo.Directory ($ScriptInfo.BaseName+'.debug.json')
    }
    if (Test-Path -Path $DebugInfoPath) {
        Write-Host "[InfinityDbg] 读取调试信息: $DebugInfoPath"
        $DebugInfo = Get-Content -Path $DebugInfoPath | ConvertFrom-Json
    }
    Write-Host "[InfinityDbg] 开始执行"
    & $ScriptPath
}
catch {
    $ErrorMessage = $_.Exception.Message
    # 先打印错误信息，然后打印映射过的堆栈信息
    Write-Host "[InfinityDbg] Error: $ErrorMessage" -ForegroundColor Red
    $StackTraceString = $_.ScriptStackTrace
    $StackTraceLines = $StackTraceString -split "\r?\n"
    foreach ($Line in $StackTraceLines) {
        Write-Host $Line -ForegroundColor Cyan
        if ($Line -match 'at\s+(\S+),\s+(.*?):\s+line\s+(\d+)' ) {
            $FunctionName = $Matches[1]
            $FilePath = $Matches[2]
            $LineNum = [int]$Matches[3]
            if($FilePath -eq (Get-Item -Path $ScriptPath).FullName) {
                $Mapping = $DebugInfo | Where-Object { $_.OutputLine -eq $LineNum }
                if ($Mapping) {
                    $SourceFile = $Mapping.SourceFile
                    $SourceLineNum = $Mapping.SourceLineNum
                    Write-Host "   -> $SourceFile`: line $SourceLineNum" -ForegroundColor Yellow
                    continue
                }
            }
        }
    }
}
 Write-Host "[InfinityDbg] 执行完毕"