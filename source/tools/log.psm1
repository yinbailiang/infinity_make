##Module InfinityMake.Tool.Log
enum LogType{
    LogErr = 0
    LogWarn = 1
    LogInfo = 2
    LogDebug = 3
}

class LogServer{
    [LogType]$LogMode
    LogServer([LogType]$Mode){
        $This.LogMode = $Mode
    }

    [void]SetMode([LogType]$Mode){
        $This.LogMode = $Mode
    }

    [void]Write([LogType]$Type,[string]$Text){
        if(([int]$Type) -gt ([int]$This.LogMode)){
            return
        }
        switch ($Type) {
            ([LogType]::LogErr) {
                Write-Host ("[Err]$Text")
            }
            ([LogType]::LogWarn) {
                Write-Host ("[Warn]$Text")
            }
            ([LogType]::LogInfo) {
                Write-Host ("[Info]$Text")
            }
            ([LogType]::LogDebug) {
                Write-Host ("[Debug]$Text")
            }
        }
    }
}

$DefaultLogServer = [LogServer]::new([LogType]::LogDebug)

class LogClient{
    [ref]$Server
    [LogType]$LogMode

    LogClient([LogType]$Mode){
        $this.Server = Get-Variable -Name 'DefaultLogServer'
        $this.LogMode = $Mode
    }

    LogClient([LogType]$Mode, [ref]$Server){
        $this.Server = $Server
        $this.LogMode = $Mode
    }

    [void]SetMode([LogType]$Mode){
        $This.LogMode = $Mode
    }

    [void]Write([string]$Text){
        $this.Server.Value.Write($this.LogMode,$Text)
    }

    [void]Write([LogType]$Type, [string]$Text){
        $this.Server.Value.Write($Type,$Text)
    }
}