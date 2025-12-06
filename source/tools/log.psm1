##Module InfinityMake.Tools.Log
##Import InfinityMake.Tools.PreDefineds

enum LogType {
    LogErr = 0      # 错误
    LogWarn = 1     # 警告
    LogInfo = 2     # 信息
    LogDebug = 3    # 调试
}

class LogServer {
    [LogType]$LogLevel
    [string]$AppName = "App"
    [bool]$EnableColors = $true
    
    LogServer([LogType]$Level) {
        $this.LogLevel = $Level
    }
    LogServer([LogType]$Level, [string]$AppName) {
        $this.LogLevel = $Level
        $this.AppName = $AppName
    }
    
    [void]SetLevel([LogType]$Level) {
        $this.LogLevel = $Level
    }
    
    [string]FormatMessage([LogType]$Type, [string]$Text) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $levelName = switch ($Type) {
            ([LogType]::LogErr) { "ERROR" }
            ([LogType]::LogWarn) { "WARN-" }
            ([LogType]::LogInfo) { "INFO-" }
            ([LogType]::LogDebug) { "DEBUG" }
        }
        return "[$timestamp][$($this.AppName)][$levelName]$Text"
    }
    
    [void]Write([LogType]$Type, [string]$Text) {
        if ([int]$Type -gt [int]$this.LogLevel) {
            return
        }
        
        $message = $this.FormatMessage($Type, $Text)
        
        if ($this.EnableColors) {
            $this.WriteColored($Type, $message)
        }
        else {
            Write-Host $message
        }
    }
    
    hidden [void]WriteColored([LogType]$Type, [string]$Message) {
        $colorCode = switch ($Type) {
            ([LogType]::LogErr) { "91" }  # 亮红色
            ([LogType]::LogWarn) { "93" }  # 亮黄色
            ([LogType]::LogInfo) { "96" }  # 亮青色
            ([LogType]::LogDebug) { "94" }  # 亮蓝色
        }
        
        Write-Host "`u{001b}[${colorCode}m$Message`u{001b}[0m"
    }
}

class LogClient {
    [LogServer]$Server
    [System.Collections.Generic.Stack[string]]$Context = @()
    
    LogClient([LogServer]$Server) {
        $this.Server = $Server
    }
    LogClient([LogType]$Level) {
        $this.Server = [LogServer]::new($Level)
    }
    
    [object]Scope([string]$ScopeName, [scriptblock]$ScriptBlock) {
        [void]$this.Context.Push($ScopeName)
        $this.Info("开始: $ScopeName")

        try {
            $Result = & $ScriptBlock
            $this.Info("完成: $ScopeName")
            return $Result
        }
        catch {
            $this.Error("$ScopeName 执行出错: $($_.Exception.Message)")
            throw
        }
        finally {
            [void]$this.Context.Pop()
        }
    }
    [object]MeasureScope([string]$ScopeName, [scriptblock]$ScriptBlock) {
        [void]$this.Context.Push($ScopeName)
        $this.Info("开始: $ScopeName")
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $Result = & $ScriptBlock
            $Stopwatch.Stop()
            $this.Info("完成: $ScopeName")
            $this.Info("耗时: $($Stopwatch.Elapsed.TotalSeconds.ToString('F3'))s")
            return $Result
        }
        catch {
            $Stopwatch.Stop()
            $this.Error("$ScopeName 执行出错: $($_.Exception.Message)")
            $this.Warn("耗时: $($Stopwatch.Elapsed.TotalSeconds.ToString('F3'))s")
            throw
        }
        finally {
            [void]$this.Context.Pop()
        }
    }
    
    # 写入日志的便捷方法
    [void]Error([string]$Message) {
        $this.WriteInternal([LogType]::LogErr, $Message)
    }
    [void]Warn([string]$Message) {
        $this.WriteInternal([LogType]::LogWarn, $Message)
    }
    [void]Info([string]$Message) {
        $this.WriteInternal([LogType]::LogInfo, $Message)
    }
    [void]Debug([string]$Message) {
        $this.WriteInternal([LogType]::LogDebug, $Message)
    }
    
    hidden [void]WriteInternal([LogType]$Type, [string]$Message) {
        $ContextPrefix = if ($this.Context.Count -ne 0) {
            $ContextArray = $this.Context.ToArray()
            [array]::Reverse($ContextArray)
            "[$($ContextArray -join '.')] " 
        }
        else { "" }
        $FullMessage = "$ContextPrefix$Message"
        
        $this.Server.Write($Type, $FullMessage)
    }
}

# 默认日志服务器
$Script:DefaultLogServer = if ($Script:DevMode -eq 'Debug') {
    [LogServer]::new([LogType]::LogDebug, "InfinityMake")
}
else {
    [LogServer]::new([LogType]::LogInfo, "InfinityMake")
}