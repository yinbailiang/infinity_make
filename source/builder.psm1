##Module InfinityMake.Builder
##Import InfinityMake.FileSystem

$Plats = @{}
function Get-Plat([string]$Name) {
    return Invoke-Command $Plats[$Name]
}

$Plats['windows'] = {

}
$Plats['mingw-w64'] = {

}

$ToolChains = @{}
function Get-ToolChain([string]$Name) {
    return Invoke-Command $ToolChains[$Name]
}
$ToolChains['msvc'] = {
    return @{
        'Builder' = {
            param([hashtable]$Project,[hashtable]$FileSystem)

        }
    }
}
$ToolChains['llvm'] = {
    return @{
        'Builder' = {
            param([hashtable]$Project,[hashtable]$FileSystem)

        }
    }
}



function Build-Project([hashtable]$Project,[hashtable]$SolutionFileSystem) {
    $ToolChain = Get-ToolChain $Project.ToolChain
    $FileSystem = Build-ProjectFileSystem $Project $SolutionFileSystem.RootDir
    return Invoke-Command $ToolChain.Builder -ArgumentList $Project,$FileSystem
}

function Build-Solution([hashtable]$Solution) {
    $SolutionFileSystem = Build-SolutionFileSystem $Solution (Get-WorkDir)

    $ProjectBuilded = [System.Collections.Generic.HashSet[string]]::new()
    $ProjectBuilding = [System.Collections.Generic.HashSet[string]]::new()

    $ProjectNameMap = @{}
    foreach($Project in $Solution.Projects){
        $ProjectNameMap[$Project.Name] = $Project
    }
    function Invoke-BuildProject([string]$ProjectName) {
        if($ProjectBuilded.Contains($ProjectName)){
            Write-Log LogDebug "<$ProjectName>IsBuilded"
            return
        }
        if($ProjectBuilding.Contains($ProjectName)){
            foreach($Name in $ProjectBuilding){
                Write-Log LogErr "CircularDependencyModule<$Name>"
            }
        }
        [void]$ProjectBuilding.Add($ProjectName)
        foreach($RequireProjectName in $ProjectNameMap[$ProjectName].Requires){
            Invoke-BuildProject $RequireProjectName
        }
        Write-Log LogInfo "BuildProject<$ProjectName>"
        Build-Project $ProjectNameMap[$ProjectName] $SolutionFileSystem
        [void]$ProjectBuilding.Remove($ProjectName)
        [void]$ProjectBuilded.Add($ProjectName)
    }

    foreach($ProjectName in $ProjectNameMap.Keys){
        Invoke-BuildProject $ProjectName
    }
}