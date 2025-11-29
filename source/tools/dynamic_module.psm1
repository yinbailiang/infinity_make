##Module InfinityMake.Tool.DynamicModule
##Import InfinityMake.Tool.FileSystem

function Import-DynamicModule([string]$ModuleName) {
    $ModulePath = Join-Path $BaseFileSystem.ResourceDir 'dynamic_modules' ($ModuleName.Replace('.','/')+'.ps1')
    . $ModulePath
}