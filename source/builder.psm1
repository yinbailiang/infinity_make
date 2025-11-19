##Module InfinityMake.Builder


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

}
$ToolChains['llvm'] = {

}



function Build-Project([hashtable]$Project) {
    #$ToolChain = Get-ToolChain $Project.ToolChain
    $FileSystem = Build-ProjectFileSystem $Project
    #return Invoke-Command $ToolChain.Builder $Project,$FileSystem
}

function Build-Solution([hashtable]$Solution) {
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
        Write-Log LogInfo "BuildProject<$ProjectName>"
        foreach($RequireProjectName in $ProjectNameMap[$ProjectName].Requires){
            Invoke-BuildProject $RequireProjectName
        }
        Build-Project $ProjectNameMap[$ProjectName]
        [void]$ProjectBuilding.Remove($ProjectName)
        [void]$ProjectBuilded.Add($ProjectName)
    }

    foreach($ProjectName in $ProjectNameMap.Keys){
        Invoke-BuildProject $ProjectName
    }
}