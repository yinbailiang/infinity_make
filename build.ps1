#region 日志函数
function Write-BuildLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[Build] $Message" -ForegroundColor Cyan
}

function Write-BuildWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[Build] WARNING: $Message" -ForegroundColor Yellow
}

function Write-BuildError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "[Build] ERROR: $Message" -ForegroundColor Red
}
#endregion

#region 初始化
# 验证 PowerShell 版本
$PSVersion = $PSVersionTable.PSVersion
if ($PSVersion.Major -lt 7) {
    Write-BuildError -Message "需要 PowerShell 7.0 或更高版本，当前版本: $PSVersion"
    exit 1
}
Write-BuildLog -Message "PowerShell 版本: $PSVersion"

$WorkFolder = Get-Location
$CacheFolder = Join-Path $WorkFolder ".buildcache"
Write-BuildLog -Message "工作目录: $WorkFolder"
Write-BuildLog -Message "缓存目录: $CacheFolder"

# 确保缓存目录存在
if (-not (Test-Path -Path $CacheFolder -PathType Container)) {
    $null = New-Item -Path $CacheFolder -ItemType Directory -Force
}

# 读取构建配置
$BuildConfig = $null
try {
    $ConfigPath = Join-Path $WorkFolder 'buildconfig.json'
    if (-not (Test-Path -Path $ConfigPath)) {
        throw "构建配置文件不存在: $ConfigPath"
    }
    
    $BuildConfig = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | 
    ConvertFrom-Json -AsHashtable -ErrorAction Stop
    Write-BuildLog -Message "构建配置: $([System.Environment]::NewLine)$($BuildConfig | ConvertTo-Json -Depth 5)"
}
catch {
    Write-BuildError -Message "加载构建配置失败: $($_.Exception.Message)"
    exit 1
}
#endregion

#region 核心函数
function Find-Files {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Filters,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $WorkFolder
    )
    
    $FoundFiles = [System.Collections.Generic.List[string]]::new()
    foreach ($Filter in $Filters) {
        $Files = Get-ChildItem -Path $BasePath -Filter $Filter -File -ErrorAction SilentlyContinue
        foreach ($File in $Files) {
            $FoundFiles.Add($File.FullName)
        }
    }
    
    return $FoundFiles.ToArray()
}
function Read-PowerShellModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath
    )
    
    Write-BuildLog -Message "读取模块: $SourceFilePath"
    
    if (-not (Test-Path -Path $SourceFilePath -PathType Leaf)) {
        throw "模块文件不存在: $SourceFilePath"
    }
    
    try {
        $FileContent = Get-Content -Path $SourceFilePath -Raw -ErrorAction Stop
    }
    catch {
        throw "读取模块文件失败 '$SourceFilePath': $($_.Exception.Message)"
    }
    
    $ModuleInfo = @{
        Name        = $null
        Requires    = [System.Collections.Generic.List[string]]::new()
        Code        = [System.Text.StringBuilder]::new()
        FilePath    = $SourceFilePath
        FileName    = Split-Path -Path $SourceFilePath -Leaf
        LineOffsets = [System.Collections.Generic.List[int]]::new()
    }

    $LineNumber = 0
    $CodeBuilder = $ModuleInfo.Code
    $Lines = $FileContent -split '\r?\n'
    
    foreach ($Line in $Lines) {
        $LineNumber++
        
        if ($Line.Trim().Length -eq 0 -or $Line.Trim().StartsWith('#')) {
            if ($Line.Trim().StartsWith('##')) {
                $Directive = $Line.Trim().Substring(2).Trim()
                $DirectiveParts = $Directive -split '\s+', 2
                
                switch ($DirectiveParts[0]) {
                    'Module' {
                        if ($DirectiveParts.Length -ge 2) {
                            $ModuleInfo.Name = $DirectiveParts[1].Trim()
                        }
                    }
                    'Import' {
                        if ($DirectiveParts.Length -ge 2) {
                            $ModuleInfo.Requires.Add($DirectiveParts[1].Trim())
                        }
                    }
                    default {
                        Write-BuildWarning -Message "未知的预处理指令: $Directive"
                        Write-BuildWarning -Message "文件: $SourceFilePath"
                        Write-BuildWarning -Message "行号: $LineNumber"
                    }
                }
            }
            continue
        }
        
        $ModuleInfo.LineOffsets.Add($LineNumber)
        
        [void]$CodeBuilder.AppendLine($Line)
    }
    
    # 验证模块信息
    if ([string]::IsNullOrWhiteSpace($ModuleInfo.Name)) {
        $ModuleInfo.Name = [System.IO.Path]::GetFileNameWithoutExtension($SourceFilePath)
    }
    
    return $ModuleInfo
}
function Build-ModuleDependencyMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleFilePaths
    )
    
    $ModuleMap = @{}
    foreach ($FilePath in $ModuleFilePaths) {
        try {
            $ModuleInfo = Read-PowerShellModule -SourceFilePath $FilePath
            $ModuleMap[$ModuleInfo.Name] = $ModuleInfo
        }
        catch {
            Write-BuildError -Message "读取模块失败 '$FilePath': $($_.Exception.Message)"
            continue
        }
    }
    
    return $ModuleMap
}
function Build-ModulesWithDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ModuleMap,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDebugInfo,
        [Parameter(Mandatory = $false)]
        [int]$DebugInfoBaseLine = 0
    )
    
    $CompiledCode = [System.Text.StringBuilder]::new()
    $LoadedModules = [System.Collections.Generic.HashSet[string]]::new()
    $LoadingStack = [System.Collections.Generic.Stack[string]]::new()
    
    function Build-ModuleInternal {
        param([string]$ModuleName)
        
        if (-not $ModuleMap.ContainsKey($ModuleName)) {
            throw "找不到模块: $ModuleName"
        }
        
        if ($LoadedModules.Contains($ModuleName)) {
            return
        }
        
        if ($LoadingStack.Contains($ModuleName)) {
            $CircularPath = $LoadingStack.ToArray() + $ModuleName
            throw "检测到循环依赖: $($CircularPath -join ' -> ')"
        }
        
        $LoadingStack.Push($ModuleName)
        
        try {
            $CurrentModuleInfo = $ModuleMap[$ModuleName]
            
            foreach ($DependencyName in $CurrentModuleInfo.Requires) {
                Build-ModuleInternal -ModuleName $DependencyName
            }
            
            Write-BuildLog -Message "构建模块: $ModuleName (来自: $($CurrentModuleInfo.FileName))"
            
            # 添加调试信息
            if ($IncludeDebugInfo) {
                [void]$CompiledCode.AppendLine("#region $ModuleName")
                [void]$CompiledCode.AppendLine("#source $($CurrentModuleInfo.FilePath)")
            }

            # 添加模块代码
            [void]$CompiledCode.Append($CurrentModuleInfo.Code.ToString())

            if ($IncludeDebugInfo) {
                [void]$CompiledCode.AppendLine("#endregion")
                [void]$CompiledCode.AppendLine()
            }
            
            [void]$LoadedModules.Add($ModuleName)
        }
        finally {
            $null = $LoadingStack.Pop()
        }
    }
    
    foreach ($CurrentModuleName in $ModuleNames) {
        try {
            Build-ModuleInternal -ModuleName $CurrentModuleName
        }
        catch {
            Write-BuildError -Message "构建模块 '$CurrentModuleName' 失败: $($_.Exception.Message)"
            throw
        }
    }
    
    return $CompiledCode.ToString().TrimEnd()
}
function Invoke-PowerShellTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestFilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ModuleMap
    )
    
    try {
        $TestModule = Read-PowerShellModule -SourceFilePath $TestFilePath
        Write-BuildLog -Message "运行测试: $($TestModule.Name)"
        
        $TestCode = [System.Text.StringBuilder]::new()
        [void]$TestCode.AppendLine('$InTest = $true')
        [void]$TestCode.AppendLine()
        
        # 构建测试依赖的模块
        $ModuleCode = Build-ModulesWithDependencies -ModuleNames $TestModule.Requires -ModuleMap $ModuleMap
        [void]$TestCode.Append($ModuleCode)
        [void]$TestCode.AppendLine()
        
        # 添加测试代码
        [void]$TestCode.Append($TestModule.Code.ToString())
        
        # 在新作用域中运行测试
        $TestScriptBlock = [scriptblock]::Create($TestCode.ToString())
        & $TestScriptBlock
    }
    catch {
        Write-BuildError -Message "测试执行失败 '$TestFilePath': $($_.Exception.Message)"
        throw
    }
}
#endregion

#region 资源处理
class ResourceFileInfo {
    [string]$FileName
    [string]$FullPath
    [string]$BasePath
    [string]$RelativePath
}
class ResourceFileHash {
    [string]$RelativePath
    [string]$Hash256
}
function Find-ResourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )
    
    $FileList = [System.Collections.Generic.List[ResourceFileInfo]]::new()
    
    # 检查BasePath是否存在
    if (-not (Test-Path -Path $BasePath -PathType Container)) {
        Write-BuildWarning -Message "资源目录不存在: $BasePath"
        return $FileList.ToArray()
    }
    
    $Files = Get-ChildItem -Path $BasePath -File -Recurse -ErrorAction SilentlyContinue
    foreach ($File in $Files) {
        try {
            $RelativePath = Resolve-Path -Path $File.FullName -Relative -RelativeBasePath $BasePath
            $FileInfo = [ResourceFileInfo]@{
                FullPath     = $File.FullName
                FileName     = $File.Name
                BasePath     = $BasePath
                RelativePath = $RelativePath
            }
            $FileList.Add($FileInfo)
        }
        catch {
            Write-BuildWarning -Message "处理文件失败 '$($File.FullName)': $($_.Exception.Message)"
        }
    }
    
    return $FileList.ToArray()
}

function Get-ResourceSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ResourceFileInfo[]]$ResourceFiles
    )
    
    $HashList = [System.Collections.Generic.List[ResourceFileHash]]::new()
    
    foreach ($ResourceFile in $ResourceFiles) {
        try {
            if (Test-Path -Path $ResourceFile.FullPath -PathType Leaf) {
                $FileHash = Get-FileHash -Path $ResourceFile.FullPath -Algorithm SHA256 -ErrorAction Stop
                
                [void]$HashList.Add([ResourceFileHash]@{
                        RelativePath = $ResourceFile.RelativePath
                        Hash256      = $FileHash.Hash
                    })
            }
            else {
                Write-BuildWarning -Message "文件不存在，跳过: $($ResourceFile.FullPath)"
            }
        }
        catch {
            Write-BuildWarning -Message "计算文件哈希失败 '$($ResourceFile.FullPath)': $($_.Exception.Message)"
        }
    }
    
    return $HashList.ToArray()
}
function Compare-ResourceSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ResourceFileHash[]]$NewSnapshot,
        
        [Parameter(Mandatory = $true)]
        [ResourceFileHash[]]$OldSnapshot
    )
    
    if ($NewSnapshot.Count -ne $OldSnapshot.Count) {
        Write-BuildLog -Message "快照文件数量不同: 新 $($NewSnapshot.Count) vs 旧 $($OldSnapshot.Count)"
    }

    $OldFileHashTable = @{}
    foreach ($Item in $OldSnapshot) {
        $OldFileHashTable[$Item.RelativePath] = $Item.Hash256
    }
    
    $IsSame = $true

    foreach ($Item in $NewSnapshot) {
        $Path = $Item.RelativePath
        if (-not $OldFileHashTable.ContainsKey($Path)) {
            Write-BuildLog -Message "新增文件: $Path"
            $IsSame = $false
            continue
        }
        if ($OldFileHashTable[$Path] -ne $Item.Hash256) {
            Write-BuildLog -Message "文件哈希变化: $Path"
            $IsSame = $false
        }
        [void]$OldFileHashTable.Remove($Path)
    }

    foreach ($Path in $OldFileHashTable.Keys) {
        Write-BuildLog -Message "文件被删除：$Path"
        $IsSame = $false
    }

    return $IsSame
}
function Write-ResourceSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ResourceFileHash[]]$Snapshot,
        
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        $SnapshotData = $Snapshot | ForEach-Object {
            @{
                RelativePath = $_.RelativePath
                Hash256      = $_.Hash256
            }
        }
        
        $SnapshotData | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Encoding UTF8
        
        Write-BuildLog -Message "资源快照已保存到: $Path"
    }
    catch {
        Write-BuildError -Message "保存资源快照失败: $($_.Exception.Message)"
        throw
    }
}
function Read-ResourceSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            return $null
        }
        
        $JsonContent = Get-Content -Path $Path -Raw -Encoding UTF8
        $SnapshotData = $JsonContent | ConvertFrom-Json
        
        $Snapshot = @()
        foreach ($Item in $SnapshotData) {
            $Snapshot += [ResourceFileHash]@{
                RelativePath = $Item.RelativePath
                Hash256      = $Item.Hash256
            }
        }
        
        Write-BuildLog -Message "已从 $Path 读取 $($Snapshot.Count) 个文件快照"
        return $Snapshot
    }
    catch {
        Write-BuildWarning -Message "读取资源快照失败: $($_.Exception.Message)"
        return $null
    }
}

function Compress-ResourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ResourceFileInfo[]]$ResourceFiles,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [System.IO.Compression.CompressionLevel]$CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    )

    if (Test-Path $DestinationPath) {
        Remove-Item -Path $DestinationPath -Force -ErrorAction SilentlyContinue
    }
    
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        
        $ZipFileStream = [System.IO.File]::Open($DestinationPath, [System.IO.FileMode]::Create)
        $ZipArchive = [System.IO.Compression.ZipArchive]::new($ZipFileStream, [System.IO.Compression.ZipArchiveMode]::Create)
        
        $FileCount = 0
        foreach ($FileInfo in $ResourceFiles) {
            if (-not (Test-Path -Path $FileInfo.FullPath -PathType Leaf)) {
                Write-BuildWarning -Message "找不到文件：$($FileInfo.FullPath)"
                Write-BuildWarning -Message "已自动跳过"
                continue
            }
            try {
                $EntryName = $FileInfo.RelativePath -replace '^\.\\', '' -replace '^\./', ''
                
                $ZipEntry = $ZipArchive.CreateEntry($EntryName, $CompressionLevel)
                $EntryStream = $ZipEntry.Open()
                $FileStream = [System.IO.File]::OpenRead($FileInfo.FullPath)
                    
                $FileStream.CopyTo($EntryStream)

                $EntryStream.Close()
                $FileStream.Close()
                    
                $FileCount++
                    
                if ($FileCount % 10 -eq 0) {
                    Write-BuildLog -Message "  已压缩 $FileCount 个文件..."
                }
            }
            catch {
                Write-BuildWarning -Message "压缩文件失败 '$($FileInfo.FullPath)': $($_.Exception.Message)"
            }
        }
        
        $ZipArchive.Dispose()
        $ZipFileStream.Close()
        
        Write-BuildLog -Message "资源压缩完成，共 $FileCount 个文件"
        
        if (Test-Path -Path $DestinationPath -PathType Leaf) {
            $ZipInfo = Get-Item -Path $DestinationPath
            Write-BuildLog -Message "ZIP文件大小: $([math]::Round($ZipInfo.Length / 1KB, 2)) KB"
        }
    }
    catch {
        Write-BuildError -Message "无法压缩资源文件：$($_.Exception.Message)"
        throw
    }
}
function Get-ResourceEmbedCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ZipFilePath
    )
    
    if (-not (Test-Path -Path $ZipFilePath -PathType Leaf)) {
        Write-BuildError -Message "ZIP文件不存在: $ZipFilePath"
        return $null
    }
    
    try {
        $ZipBytes = [System.IO.File]::ReadAllBytes($ZipFilePath)
        $ZipHash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new($ZipBytes)) -Algorithm SHA256
        $Base64Data = [System.Convert]::ToBase64String($ZipBytes)
        
        $ResourceCode = @"
`$BuiltinResourceZipHash = "$($ZipHash.Hash)"
`$BuiltinResourceZipContent = [System.Convert]::FromBase64String("$Base64Data")
"@
        
        Write-BuildLog -Message "生成资源嵌入代码 (代码大小: $([math]::Round($ResourceCode.Length / 1KB, 2)) KB)"
        return $ResourceCode
    }
    catch {
        Write-BuildError -Message "生成资源嵌入代码失败: $($_.Exception.Message)"
        return $null
    }
}
#endregion

#region 构建流程
try {
    # 1. 查找并构建模块
    $SourceFiles = Find-Files -Filters $BuildConfig.SourcePath
    Write-BuildLog -Message "找到源文件: $($SourceFiles.Count) 个"
    
    $ModuleMap = Build-ModuleDependencyMap -ModuleFilePaths $SourceFiles
    Write-BuildLog -Message "构建模块映射: $($ModuleMap.Count) 个模块"
    
    # 2. 运行测试
    if ($BuildConfig.TestPath -and $BuildConfig.TestPath.Count -gt 0) {
        $TestFiles = Find-Files -Filters $BuildConfig.TestPath
        Write-BuildLog -Message "找到测试文件: $($TestFiles.Count) 个"
        
        if ($TestFiles.Count -gt 0) {
            Write-BuildLog -Message "开始运行测试 -------------------------------------------------"
            
            $TestPassed = $true
            foreach ($TestFile in $TestFiles) {
                try {
                    Invoke-PowerShellTest -TestFilePath $TestFile -ModuleMap $ModuleMap
                    Write-BuildLog -Message "测试通过"
                }
                catch {
                    Write-BuildError -Message "测试失败: $(Split-Path -Path $TestFile -Leaf)"
                    Write-BuildError -Message "失败信息: $($_.Exception.Message)"
                    $TestPassed = $false
                }
            }
            
            if (-not $TestPassed) {
                Write-BuildError -Message "部分测试失败，构建中止"
                exit 1
            }
            
            Write-BuildLog -Message "测试完成 -------------------------------------------------"
        }
    }
    
    # 3. 处理资源文件
    $ResourceCode = $null
    if ($BuildConfig.ResourcePath) {
        Write-BuildLog -Message "查找资源文件: $($BuildConfig.ResourcePath)"
        
        $ResourceFiles = Find-ResourceFiles -BasePath $BuildConfig.ResourcePath
        Write-BuildLog -Message "找到资源文件: $($ResourceFiles.Count) 个"
        
        if ($ResourceFiles.Count -gt 0) {
            $Snapshot = Get-ResourceSnapshot -ResourceFiles $ResourceFiles
            $CacheSnapshotFilePath = Join-Path $CacheFolder 'resource_snapshot.json'
            $CacheZipFilePath = Join-Path $CacheFolder 'resource.zip'
            
            # 检查是否需要更新缓存
            $NeedUpdate = $true
            $CacheSnapshot = Read-ResourceSnapshot -Path $CacheSnapshotFilePath
            
            if ($CacheSnapshot -and (Test-Path -Path $CacheZipFilePath -PathType Leaf)) {
                if (Compare-ResourceSnapshot -NewSnapshot $Snapshot -OldSnapshot $CacheSnapshot) {
                    Write-BuildLog -Message "资源未变化，使用缓存"
                    $NeedUpdate = $false
                }
                else {
                    Write-BuildLog -Message "资源已变化，需要更新缓存"
                }
            }
            else {
                Write-BuildLog -Message "无缓存或缓存不完整，创建新缓存"
            }
            
            if ($NeedUpdate) {
                Write-BuildLog -Message "开始压缩资源文件..."
                Compress-ResourceFiles -ResourceFiles $ResourceFiles -DestinationPath $CacheZipFilePath
                Write-ResourceSnapshot -Path $CacheSnapshotFilePath -Snapshot $Snapshot
            }
            
            # 生成资源嵌入代码
            $ResourceCode = Get-ResourceEmbedCode -ZipFilePath $CacheZipFilePath
        }
        else {
            Write-BuildLog -Message "未找到资源文件"
        }
    }
    
    # 4. 构建预定义变量
    $PreDefinedsCode = $null
    if($BuildConfig.Version){
        $BuildConfig.PreDefineds['Version'] = $BuildConfig.Version
    }
    if ($BuildConfig.PreDefineds -and $BuildConfig.PreDefineds.Count -gt 0) {
        $PreDefinedsBuilder = [System.Text.StringBuilder]::new()
        foreach ($Variable in $BuildConfig.PreDefineds.GetEnumerator()) {
            Write-BuildLog -Message "构建预定义变量：$($Variable)"
            if ($Variable.Value -is [string]) {
                [void]$PreDefinedsBuilder.AppendLine("`$$($Variable.Name) = '$($Variable.Value.Replace("'", "''"))'")
            }
            elseif ($Variable.Value -is [bool]) {
                [void]$PreDefinedsBuilder.AppendLine("`$$($Variable.Name) = `$$($Variable.Value.ToString().ToLower())")
            }
            else {
                [void]$PreDefinedsBuilder.AppendLine("`$$($Variable.Name) = $($Variable.Value)")
            }
        }
        $PreDefinedsCode = $PreDefinedsBuilder.ToString().TrimEnd()
        Write-BuildLog -Message "预定义变量构建完成: $($BuildConfig.PreDefineds.Count) 个变量"
    }
    
    # 5. 构建输出脚本
    $OutputFileName = if ($BuildConfig.Name) { 
        "$($BuildConfig.Name).ps1" 
    }
    else { 
        "output.ps1" 
    }
    $OutputPath = Join-Path $WorkFolder $OutputFileName
    
    Write-BuildLog -Message "构建输出文件: $OutputPath"
    
    # 保证稳定的构建顺序
    $AllModuleNames = $ModuleMap.Keys | Sort-Object
    
    $FinalCode = Build-ModulesWithDependencies `
        -ModuleNames $AllModuleNames `
        -ModuleMap $ModuleMap `
        -IncludeDebugInfo
    
    # 写入输出文件
    try {
        $StreamWriter = $null
        try {
            $StreamWriter = [System.IO.StreamWriter]::new($OutputPath, $false, [System.Text.Encoding]::UTF8)
            
            $StreamWriter.WriteLine("<#")
            $StreamWriter.WriteLine("BuildTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            $StreamWriter.WriteLine("ModuleCount: $($ModuleMap.Count)")
            if ($ResourceCode) {
                $StreamWriter.WriteLine("BuiltinResource: true")
            }
            if ($BuildConfig.Version){
                $StreamWriter.WriteLine("Version: $($BuildConfig.Version)")
            }
            $StreamWriter.WriteLine("#>")
            $StreamWriter.WriteLine()
            
            if ($ResourceCode) {
                $StreamWriter.WriteLine("#region builtin_resource")
                $StreamWriter.WriteLine($ResourceCode)
                $StreamWriter.WriteLine("#endregion")
                $StreamWriter.WriteLine()
            }
            
            if ($PreDefinedsCode) {
                $StreamWriter.WriteLine("#region predefineds")
                $StreamWriter.WriteLine($PreDefinedsCode)
                $StreamWriter.WriteLine("#endregion")
                $StreamWriter.WriteLine()
            }
            
            $StreamWriter.WriteLine("#region module")
            $StreamWriter.WriteLine($FinalCode)
            $StreamWriter.WriteLine("#endregion")
            $StreamWriter.WriteLine()
            
            $StreamWriter.WriteLine("#region main")
            $StreamWriter.WriteLine('$ExitCode = 0')
            $StreamWriter.WriteLine('try {')
            $StreamWriter.WriteLine('    $ExitCode = Invoke-Main -ArgumentList $args')
            $StreamWriter.WriteLine('}')
            $StreamWriter.WriteLine('catch {')
            $StreamWriter.WriteLine('    Write-Error "$($_.Exception.Message)"')
            $StreamWriter.WriteLine('    $ExitCode = 1')
            $StreamWriter.WriteLine('}')
            $StreamWriter.WriteLine('exit $ExitCode')
            $StreamWriter.Write("#endregion")
            
            Write-BuildLog -Message "输出文件写入完成: $OutputPath"
        }
        finally {
            if ($null -ne $StreamWriter) {
                $StreamWriter.Flush()
                $StreamWriter.Close()
                $StreamWriter.Dispose()
            }
        }
        
        if (Test-Path -Path $OutputPath -PathType Leaf) {
            $FileInfo = Get-Item -Path $OutputPath
            Write-BuildLog -Message "输出文件大小: $([math]::Round($FileInfo.Length / 1KB, 2)) KB"
        }
    }
    catch {
        Write-BuildError -Message "写入输出文件失败: $($_.Exception.Message)"
        throw
    }
    
    Write-BuildLog -Message "构建完成!"
}
catch {
    Write-BuildError -Message "构建过程失败: $($_.Exception.Message)"
    Write-BuildError -Message "堆栈跟踪: $($_.ScriptStackTrace)"
    exit 1
}
#endregion