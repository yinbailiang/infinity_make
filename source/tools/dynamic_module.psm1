##Module InfinityMake.DynamicModule


function Import-DynamicModule([string]$ModuleFilePath) {
    $ModuleContent = Get-Content -Path $ModuleFilePath
    foreach($Line in $ModuleFilePath){
        
    }
}