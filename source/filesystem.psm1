##Module InfinityMake.FileSystem
##Import InfinityMake.Log

class ProjectFileSystem{

}
class SolutionFileSystem{
    [System.Collections.Hashtable]$ProjectFileSystem
}
class BaseFileSystem{
    [string]$WorkDir
    [string]$CacheDir
    [string]$ResoureDir
    BaseFileSystem(){
        $This.WorkDir = Get-Location
        $This.CacheDir = Join-Path $This.WorkDir '.infmake'
        $This.ResoureDir = Join-Path $This.WorkDir '.infmakeres'
        
    }
}