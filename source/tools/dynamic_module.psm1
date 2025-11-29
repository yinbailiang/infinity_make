##Module InfinityMake.Tools.DynamicModule
##Import InfinityMake.Tools.FileSystem

function Import-DynamicModule([string]$ModuleName) {
    $ModulePath = Join-Path $BaseFileSystem.ResourceDir 'dynamic_modules' ($ModuleName.Replace('.','/')+'.ps1')
    . $ModulePath
}