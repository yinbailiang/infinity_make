##Module InfinityMake.Tools.Log
enum LogType{
    LogErr = 0
    LogWarn = 1
    LogInfo = 2
    LogDebug = 3
}

class LogServer {
    [LogType]$LogMode
    LogServer([LogType]$Mode) {
        $This.LogMode = $Mode
    }

    [void]SetMode([LogType]$Mode) {
        $This.LogMode = $Mode
    }

    [void]Write([LogType]$Type, [string]$Text) {
        if (([int]$Type) -gt ([int]$This.LogMode)) {
            return
        }
        switch ($Type) {
            ([LogType]::LogErr) {
                Write-Host ("`u{001b}[38;2;255;0;0m[Err  ]$($Text)")
            }
            ([LogType]::LogWarn) {
                Write-Host ("`u{001b}[38;2;255;255;0m[Warn ]$($Text)")
            }
            ([LogType]::LogInfo) {
                Write-Host ("`u{001b}[38;2;0;255;255m[Info ]$($Text)")
            }
            ([LogType]::LogDebug) {
                Write-Host ("`u{001b}[38;2;0;0;255m[Debug]$($Text)")
            }
        }
    }
}

$DefaultLogServer = if ($DevMode -eq 'Debug') {
    [LogServer]::new([LogType]::LogDebug)
}
else {
    [LogServer]::new([LogType]::LogInfo)
}

class LogClient {
    [ref]$Server = $DefaultLogServer
    [LogType]$LogMode
    [int]$IndentationCount = 0
    [string]$IndentationStr = '    '

    LogClient([LogType]$Mode) {
        $this.LogMode = $Mode
    }

    LogClient([LogType]$Mode, [ref]$Server) {
        $this.Server = $Server
        $this.LogMode = $Mode
    }

    [void]SetMode([LogType]$Mode) {
        $This.LogMode = $Mode
    }

    [void]OpenIndentationField([scriptblock]$Field){
        $this.IndentationCount += 1
        foreach($Temp in $Field.Invoke()){
            $this.Write($Temp)
        }
        $this.IndentationCount -= 1
    }

    [void]Write([string]$Text) {
        $this.Write($this.LogMode,$Text)
    }

    [void]Write([LogType]$Type, [string]$Text) {
        foreach($Line in $Text.Split([System.Environment]::NewLine)){
            $this.Server.Value.Write($Type, $this.IndentationStr * $this.IndentationCount + $Line)
        }
    }
}