##Module InfinityMake.FileSystem
##Import InfinityMake.Log

$WorkFolder = Get-Location
function Get-WorkDir {
    return $WorkFolder
}


function New-Folder([string]$Path) {
    if(Test-Path -Path $Path -PathType Container){
        Write-Log LogDebug ("FindFolder<$Path>")
    }else{
        Write-Log LogDebug ("NotFindFolder<$Path>")
        New-Item -Path $Path -ItemType Directory | Out-Null
        Write-Log LogDebug ("CreateFolder<$Path>")
    }
}

function Build-SolutionFileSystem([hashtable]$Solution,[string]$RootDir) {
    $SolutionRootDir = Join-Path $RootDir $Solution.Name
    New-Folder $SolutionRootDir
    return @{
        'WorkDir' = (Get-WorkDir)
        'RootDir' = $SolutionRootDir
    }
}

function Build-ProjectFileSystem([hashtable]$Project,[hashtable]$SolutionFileSystem) {
    $ProjectRootDir = Join-Path $SolutionFileSystem.RootDir $Project.Name
    New-Folder $ProjectRootDir
    $ProjectDir = Join-Path $ProjectRootDir $Project.Plat $Project.ToolChain $Project.Arch
    New-Folder $ProjectDir
    $ProjectObjsDir = Join-Path $ProjectDir '.objs'
    New-Folder $ProjectObjsDir
    $ProjectCacheDir = Join-Path $ProjectDir '.cache'
    New-Folder $ProjectCacheDir
    $ProjectTempDir = Join-Path $ProjectDir '.temp'
    if(Test-Path -Path $ProjectTempDir -PathType Container){
        Remove-Item $ProjectTempDir -Recurse
    }
    New-Folder $ProjectTempDir
    return @{
        'SolutionFileSystem' = $SolutionFileSystem
        'RootDir' = $ProjectRootDir
        'BuildDir' = $ProjectDir
        'ObjsDir' = $ProjectObjsDir
        'CacheDir' = $ProjectCacheDir
        'TempDir' = $ProjectTempDir
    }
}