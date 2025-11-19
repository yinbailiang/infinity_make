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
        Write-Log LogInfo ("CreateFolder<$Path>")
    }
}

function Build-SolutionFileSystem([hashtable]$Solution,[string]$RootDir) {
    $SolutionRootDir = Join-Path $RootDir $Solution.Name
    New-Folder $SolutionRootDir
    return @{
        'RootDir' = $SolutionRootDir
    }
}

function Build-ProjectFileSystem([hashtable]$Project,[string]$RootDir) {
    $ProjectRootDir = Join-Path $RootDir $Project.Name
    New-Folder $ProjectRootDir
    $ProjectTargetDir = Join-Path $ProjectTargetDir $Project.Plat $Project.ToolChain $Project.Arch
    New-Folder $ProjectTargetDir
    $ProjectTargetObjsDir = Join-Path $ProjectTargetObjsDir 'objs'
    New-Folder $ProjectTargetObjsDir
}