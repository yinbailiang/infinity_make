$IMModules = ConvertFrom-Json -AsHashtable -InputObject '{"InfintyMake.Solution":{"Requires":[],"Code":""},"InfintyMake.Main":{"Requires":["InfintyMake.Solution"],"Code":"\r\nfunction Invoke-Main([string[]]$ArgumentList) {\r\n    Write-Host $ArgumentList\r\n    return 0\r\n}\r\n"}}'
$ModuleLoaded = [System.Collections.Generic.HashSet[string]]::new()
function Import-IMModule([string]$ModuleName) {
    if ($ModuleLoaded.Contains($ModuleName)) {
        return
    }
    foreach ($RequireModuleName in $IMModules[$ModuleName].Requires) {
        Import-IMModule $RequireModuleName
    }
    Write-Host "LoadModule<$ModuleName>" -ForegroundColor Blue
    if (-not $IMModules.ContainsKey($ModuleName)) {
        Write-Host "CanNotFindModule<$ModuleName>" -ForegroundColor Red
        return
    }
    [void]$ModuleLoaded.Add($ModuleName)
    
    $Code = $IMModules[$ModuleName].Code
    Invoke-Expression "New-Module -Name $ModuleName -ScriptBlock {$Code}" | Import-Module -Scope Local
}

foreach ($ModuleName in $IMModules.Keys) {
    Import-IMModule $ModuleName
}

$Ret = Invoke-Main $args

if ($Ret -ne 0) {
    Write-Host "ExitCode<$Ret>" -ForegroundColor Red
}
else {
    Write-Host "ExitCode<$Ret>" -ForegroundColor Blue
}

foreach ($ModuleName in $ModuleLoaded) {
    Write-Host "RemoveModule<$ModuleName>" -ForegroundColor Blue
    Remove-Module -Name $ModuleName
}
