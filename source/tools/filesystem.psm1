##Module InfinityMake.Tools.FileSystem
##Import InfinityMake.Tools.Log

#region 缓存管理
# 定义模块内部的版本标识文件名
$Script:CacheVersionFileName = ".inf_cache_version"

function Test-CacheValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CachePath,

        [Parameter(Mandatory = $true)]
        [string]$VersionKey
    )

    $Logger = [LogClient]::new($Script:DefaultLogServer)
    $VersionFilePath = Join-Path $CachePath $Script:CacheVersionFileName

    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        $Logger.Debug("目录不存在：$CachePath")
        return $false
    }
    if (-not (Test-Path -Path $VersionFilePath -PathType Leaf)) {
        $Logger.Debug("版本标识文件不存在：$VersionFilePath")
        return $false
    }

    try {
        $CachedVersion = (Get-Content -Path $VersionFilePath -Raw -ErrorAction Stop).Trim()
        $IsValid = ($CachedVersion -eq $VersionKey)

        if ($IsValid) {
            $Logger.Debug("验证通过。路径：$CachePath, 版本：$VersionKey")
        }
        else {
            $Logger.Debug("版本不匹配。期望：$VersionKey, 实际：$CachedVersion")
        }
        return $IsValid
    }
    catch {
        $Logger.Warn("读取版本文件失败：$($_.Exception.Message)")
        return $false
    }
}
function Write-CacheVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CachePath,

        [Parameter(Mandatory = $true)]
        [string]$VersionKey
    )

    $Logger = [LogClient]::new($Script:DefaultLogServer)
    $VersionFilePath = Join-Path $CachePath $Script:CacheVersionFileName

    try {
        if (-not (Test-Path -Path $CachePath -PathType Container)) {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
            $Logger.Info("创建目录：$CachePath")
        }

        Set-Content -Path $VersionFilePath -Value $VersionKey -Encoding UTF8 -Force -NoNewLine
        $Logger.Debug("版本标识已更新。路径：$CachePath, 版本：$VersionKey")
    }
    catch {
        $Logger.Error("写入版本标识失败：$($_.Exception.Message)")
        throw
    }
}

function Clear-Cache {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$CachePath,

        [Parameter(Mandatory = $false)]
        [string]$VersionKey,

        [Parameter(Mandatory = $false)]
        [int]$OlderThanDays,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $Logger = [LogClient]::new($Script:DefaultLogServer)

    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        $Logger.Info("缓存目录不存在，无需清理：$CachePath")
        return
    }

    if ($Force -and (Test-Path -Path $CachePath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($CachePath, '强制删除整个缓存目录')) {
            Remove-Item -Path $CachePath -Recurse -Force
            $Logger.Info("已强制删除缓存目录：$CachePath")
        }
        return
    }

    $ChildItems = Get-ChildItem -Path $CachePath -Directory -ErrorAction SilentlyContinue
    foreach ($Item in $ChildItems) {
        $ItemPath = $Item.FullName
        $ShouldRemove = $false
        $Reason = ""

        # 检查版本是否匹配
        if ($PSBoundParameters.ContainsKey('VersionKey')) {
            $IsValid = Test-CacheValid -CachePath $ItemPath -VersionKey $VersionKey
            if (-not $IsValid) {
                $ShouldRemove = $true
                $Reason = "版本不匹配"
            }
        }

        # 检查是否过期
        if ($PSBoundParameters.ContainsKey('OlderThanDays')) {
            $ItemAge = (Get-Date) - $Item.LastWriteTime
            if ($ItemAge.TotalDays -gt $OlderThanDays) {
                $ShouldRemove = $true
                $Reason = "已过期（超过 $OlderThanDays 天）"
            }
        }

        # 执行删除
        if ($ShouldRemove -and $PSCmdlet.ShouldProcess($ItemPath, "删除缓存目录（原因：$Reason）")) {
            try {
                Remove-Item -Path $ItemPath -Recurse -Force
                $Logger.Info("已清理缓存：$($Item.Name) - $Reason")
            }
            catch {
                $Logger.Warn("清理缓存目录失败 $($Item.Name)：$($_.Exception.Message)")
            }
        }
    }
    $Logger.Info("缓存清理完成。")
}
#endregion

#region 资源管理
class BuiltinResourceInfo {
    [byte[]]$ResourceZipData
    [string]$ResourceZipHash
}

function Get-BuiltinResource {
    $Logger = [LogClient]::new($Script:DefaultLogServer)

    if ((-not $Script:BuiltinResourceZipContent) -or (-not $Script:BuiltinResourceZipHash)) {
        $Logger.Warn("未找到内置资源数据或内置资源数据不完整")
        return $null
    }

    try {
        $ComputedHash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new($Script:BuiltinResourceZipContent)) -Algorithm SHA256
        if ($ComputedHash.Hash -eq $Script:BuiltinResourceZipHash) {
            $Logger.Info("内置资源哈希校验成功")
            return [BuiltinResourceInfo]@{
                ResourceZipData = $Script:BuiltinResourceZipContent
                ResourceZipHash = $Script:BuiltinResourceZipHash
            }
        }
        else {
            $Logger.Error("内置资源哈希校验失败")
            return $null
        }
    }
    catch {
        $Logger.Error("内置资源哈希校验时发生异常：$($_.Exception.Message)")
        return $null
    }
}

function Expand-BuiltinResource {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [BuiltinResourceInfo]$ResourceInfo,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $Logger = [LogClient]::new($Script:DefaultLogServer)
    $Logger.Info("开始释放资源到：$DestinationPath")

    $CacheIsValid = $false
    if (-not $Force) {
        $CacheIsValid = Test-CacheValid -CachePath $DestinationPath -VersionKey $ResourceInfo.ResourceZipHash
        if ($CacheIsValid) {
            $Logger.Info("资源有效，跳过解压")
            return
        }
    }

    $TempZipPath = Join-Path $env:TEMP "resource_$([guid]::NewGuid().ToString('N')).zip"

    try {
        $Logger.Debug("创建临时ZIP文件：$TempZipPath")
        [System.IO.File]::WriteAllBytes($TempZipPath, $ResourceInfo.ResourceZipData)

        if (Test-Path -Path $DestinationPath -PathType Container) {
            if (-not $CacheIsValid) {
                $Logger.Info("清空现有目标目录：$DestinationPath")
                Remove-Item -Path "$DestinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
            $Logger.Info("创建目标目录：$DestinationPath")
        }

        $Logger.Info("正在解压资源...")
        Expand-Archive -Path $TempZipPath -DestinationPath $DestinationPath -Force

        Write-CacheVersion -CachePath $DestinationPath -VersionKey $ResourceInfo.ResourceZipHash

        $Logger.Info("资源释放并缓存完成：$DestinationPath")
    }
    catch {
        $Logger.Error("释放资源失败：$($_.Exception.Message)")
        throw
    }
    finally {
        if (Test-Path -Path $TempZipPath) {
            Remove-Item -Path $TempZipPath -Force -ErrorAction SilentlyContinue
        }
        $Logger.Debug("已清理临时文件")
    }
}

function Initialize-FileSystem {
    [CmdletBinding()]
    param()

    $Logger = [LogClient]::new($Script:DefaultLogServer)
    $Logger.Info("初始化文件系统...")

    $WorkDir = Get-Location
    $FileSystemRootDir = Join-Path $WorkDir '.infmake'
    $CacheDir = Join-Path $FileSystemRootDir '.cache'

    if (-not (Test-Path -Path $FileSystemRootDir -PathType Container)) {
        New-Item -Path $FileSystemRootDir -ItemType Directory -Force | Out-Null
        $Logger.Info("创建文件系统根目录：$FileSystemRootDir")
    }
    if (-not (Test-Path -Path $CacheDir -PathType Container)) {
        New-Item -Path $CacheDir -ItemType Directory -Force | Out-Null
        $Logger.Info("创建缓存目录：$CacheDir")
    }

    $ResourceDir = $null
    $BuiltinResource = Get-BuiltinResource
    if ($BuiltinResource) {
        $ResourceDir = Join-Path $FileSystemRootDir ".resource"

        $Logger.Info("找到内嵌资源")
        try {
            Expand-BuiltinResource -ResourceInfo $BuiltinResource -DestinationPath $ResourceDir
        }
        catch {
            $Logger.Warn("资源释放失败，资源目录将不可用")
            $ResourceDir = $null
        }
    }
    else {
        $Logger.Info("未找到有效的内置资源")
    }

    # 返回文件系统信息对象
    $FileSystemInfo = @{
        WorkDir           = $WorkDir
        FileSystemRootDir = $FileSystemRootDir
        CacheDir          = $CacheDir
    }
    if ($ResourceDir) {
        $FileSystemInfo['ResourceDir'] = $ResourceDir
    }
    $Logger.Info("文件系统初始化完成")
    return $FileSystemInfo
}

# 模块初始化时自动构建文件系统
$Script:FileSystem = Initialize-FileSystem
#endregion