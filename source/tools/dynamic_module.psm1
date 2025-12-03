##Module InfinityMake.Tools.DynamicModule
##Import InfinityMake.Tools.FileSystem
##Import InfinityMake.Tools.Log

function Get-DynamicModule{
    return Get-ChildItem -Path (Join-Path $BaseFileSystem.ResourceDir 'dynamic_modules') -Filter "*.ps1" -Recurse
}

function Import-DynamicModule([string]$ModuleName) {
    $Loger = [LogClient]::new([LogType]::LogDebug)
    $Loger.Write("Import-DynamicModule $($ModuleName)")
    $ModulePath = Join-Path $BaseFileSystem.ResourceDir 'dynamic_modules' ($ModuleName.Replace('.', '/') + '.ps1')
    $Loger.OpenIndentationField{
        "DynamicModulePath $($ModulePath)"
    }
    . $ModulePath
}

function Import-CSharpDynamicModule([string]$ModuleName) {
}