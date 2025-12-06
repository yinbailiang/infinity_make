##Module InfinityMake.Tools.Log.Test
##Import InfinityMake.Tools.Log

$TestLogServer = [LogServer]::new([LogType]::LogDebug, "InfinityMake.Test")
$TestLoger = [LogClient]::new($TestLogServer)

function Test-LogLevels {
    Write-Host "=== 测试日志级别过滤 ===" -ForegroundColor Cyan
    
    # 测试不同日志级别的服务器
    $levels = @([LogType]::LogErr, [LogType]::LogWarn, [LogType]::LogInfo, [LogType]::LogDebug)
    
    foreach ($level in $levels) {
        Write-Host "`n设置日志级别为: $($level.ToString())" -ForegroundColor Yellow
        $server = [LogServer]::new($level, "TestLevel")
        $logger = [LogClient]::new($server)
        
        $logger.Error("错误消息测试")
        $logger.Warn("警告消息测试")
        $logger.Info("信息消息测试")
        $logger.Debug("调试消息测试")
        
        Write-Host "---" -ForegroundColor DarkGray
    }
}

function Test-ScopeAndMeasure {
    Write-Host "`n=== 测试作用域和时间测量 ===" -ForegroundColor Cyan
    
    # 测试普通作用域
    $result = $TestLoger.Scope("测试作用域", {
        $TestLoger.Info("在作用域内执行操作")
        return "操作完成"
    })
    Write-Host "作用域返回结果: $result" -ForegroundColor Green
    
    # 测试嵌套作用域
    $TestLoger.Scope("外层作用域", {
        $TestLoger.Info("外层操作")
        
        $TestLoger.Scope("内层作用域", {
            $TestLoger.Info("内层操作")
        })
    })
    
    # 测试时间测量
    $TestLoger.MeasureScope("耗时操作测试", {
        $TestLoger.Info("模拟耗时操作...")
        Start-Sleep -Milliseconds 300
        $TestLoger.Info("操作完成")
    })
}

function Test-ErrorHandling {
    Write-Host "`n=== 测试错误处理 ===" -ForegroundColor Cyan
    
    # 测试作用域内的错误处理
    try {
        $TestLoger.Scope("错误测试作用域", {
            $TestLoger.Info("开始执行...")
            throw "模拟的运行时错误"
        })
    }
    catch {
        Write-Host "成功捕获异常: $_" -ForegroundColor Red
    }
    
    # 测试MeasureScope的错误处理
    try {
        $TestLoger.MeasureScope("错误计时测试", {
            Start-Sleep -Milliseconds 100
            throw "计时测试中的错误"
        })
    }
    catch {
        Write-Host "成功捕获MeasureScope异常: $_" -ForegroundColor Red
    }
}

function Test-ContextStack {
    Write-Host "`n=== 测试上下文堆栈 ===" -ForegroundColor Cyan
    
    # 测试多层级上下文
    $TestLoger.Scope("任务1", {
        $TestLoger.Info("任务1开始执行")
        
        $TestLoger.Scope("子任务1.1", {
            $TestLoger.Info("子任务1.1执行中")
            
            $TestLoger.Scope("孙子任务1.1.1", {
                $TestLoger.Info("这是最内层的任务")
                $TestLoger.Debug("调试信息：当前在孙子任务中")
            })
            
            $TestLoger.Info("返回子任务1.1")
        })
        
        $TestLoger.Scope("子任务1.2", {
            $TestLoger.Warn("子任务1.2遇到警告")
        })
    })
}

function Test-ColorOutput {
    Write-Host "`n=== 测试颜色输出 ===" -ForegroundColor Cyan
    
    # 创建禁用颜色的服务器
    $noColorServer = [LogServer]::new([LogType]::LogDebug, "NoColorTest")
    $noColorServer.EnableColors = $false
    $noColorLogger = [LogClient]::new($noColorServer)
    
    Write-Host "`n无颜色输出:" -ForegroundColor Yellow
    $noColorLogger.Error("无颜色错误消息")
    $noColorLogger.Warn("无颜色警告消息")
    $noColorLogger.Info("无颜色信息消息")
    $noColorLogger.Debug("无颜色调试消息")
    
    Write-Host "`n有颜色输出:" -ForegroundColor Yellow
    $TestLoger.Error("有颜色错误消息")
    $TestLoger.Warn("有颜色警告消息")
    $TestLoger.Info("有颜色信息消息")
    $TestLoger.Debug("有颜色调试消息")
}

function Test-MessageFormatting {
    Write-Host "`n=== 测试消息格式化 ===" -ForegroundColor Cyan
    
    # 测试服务器不同应用名称
    $app1 = [LogServer]::new([LogType]::LogInfo, "App1")
    $app2 = [LogServer]::new([LogType]::LogInfo, "App2")
    
    $logger1 = [LogClient]::new($app1)
    $logger2 = [LogClient]::new($app2)
    
    $logger1.Info("来自App1的消息")
    $logger2.Info("来自App2的消息")
    
    # 测试动态修改日志级别
    $dynamicServer = [LogServer]::new([LogType]::LogWarn, "DynamicTest")
    $dynamicLogger = [LogClient]::new($dynamicServer)
    
    $dynamicLogger.Info("这条信息不应该显示（当前级别Warn）")
    $dynamicLogger.Warn("这条警告应该显示")
    
    $dynamicServer.SetLevel([LogType]::LogInfo)
    $dynamicLogger.Info("现在信息应该显示了")
}

function Test-Performance {
    Write-Host "`n=== 测试性能 ===" -ForegroundColor Cyan
    
    $iterations = 100
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 1; $i -le $iterations; $i++) {
        $TestLoger.Debug("性能测试消息 $i")
    }
    
    $stopwatch.Stop()
    
    Write-Host "写入 $iterations 条日志耗时: $($stopwatch.Elapsed.TotalMilliseconds.ToString('F2'))ms" -ForegroundColor Green
    Write-Host "平均每条: $(($stopwatch.Elapsed.TotalMilliseconds / $iterations).ToString('F3'))ms" -ForegroundColor Green
}

function Run-AllLogTests {
    Write-Host "开始运行日志模块测试..." -ForegroundColor Green
    
    try {
        Test-LogLevels
        Test-ScopeAndMeasure
        Test-ErrorHandling
        Test-ContextStack
        Test-ColorOutput
        Test-MessageFormatting
        Test-Performance

        Write-Host "验证默认日志服务器..." -ForegroundColor Green
        [LogClient]::new($Script:DefaultLogServer).Info("测试默认日志服务器")

        Write-Host "所有测试完成！" -ForegroundColor Green
    }
    catch {
        Write-Host "`n测试过程中发生错误: $_" -ForegroundColor Red
        Write-Host "错误详情: $($_.ScriptStackTrace)" -ForegroundColor Red
        throw
    }
}

#Run-AllLogTests