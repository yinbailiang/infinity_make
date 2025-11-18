[string]$WorkFolder = Get-Location
[string]$SourcePath = Join-Path $WorkFolder 'Source'
[string[]]$SourceFiles = Get-ChildItem -Path $SourcePath -Filter '*.psm1' -Recurse -File

function Get-Module([string]$SourceFile) {
    $Code = Get-Content $SourceFile
    $Module = @{
        'Name'     = $null
        'Requires' = @()
        'Code'     = ''
    }
    foreach ($Line in $Code) {
        if ($Line.Length -lt 2 -or $Line.Substring(0, 2) -ne '##') {
            $Module.Code += $Line + [System.Environment]::NewLine
            continue
        }
        $Line = $Line.Remove(0, 2)
        $WordList = $Line.Split(' ')
        switch ($WordList[0]) {
            'Module' {
                $Module.Name = $WordList[1]
            }
            'Import' {
                $Module.Requires += $WordList[1]
            }
            default {
                Write-Error ("UnknowPreProcessCommand<$Line>")
            }
        }
    }
    return $Module
}

$ModuleMap = @{}
$SourceFiles | ForEach-Object {
    $Module = Get-Module $_
    $ModuleMap[$Module.Name] = @{
        'Requires' = $Module.Requires
        'Code'     = $Module.Code
    }
}

$LightMake = [System.IO.StreamWriter]::new('infinity_make.ps1')
[void]$LightMake.WriteLine('$ModuleList = @()')
$ModuleLoaded = [System.Collections.Generic.HashSet[string]]::new()
$ModuleLoading = [System.Collections.Generic.HashSet[string]]::new()
function Add-Module($ModuleName) {
    if($ModuleLoaded.Contains($ModuleName)){
        return
    }
    if($ModuleLoading.Contains($ModuleName)){
        foreach($Name in $ModuleLoading){
            Write-Error "CircularDependencyModule<$Name>“
        }
        return
    }
    [void]$ModuleLoading.Add($ModuleName)
    foreach($RequireModuleName in $ModuleMap[$ModuleName].Requires){
        Add-Module $RequireModuleName
    }
    [void]$LightMake.WriteLine('$ModuleList += "{0}"' -f $ModuleName)
    [void]$LightMake.WriteLine('New-Module -Name "{0}" -ScriptBlock {{{1}}} | Import-Module' -f @($ModuleName,$ModuleMap[$ModuleName].Code))
    [void]$ModuleLoading.Remove($ModuleName)
    [void]$ModuleLoaded.Add($ModuleName)
}

foreach($Name in $ModuleMap.Keys){
    Add-Module $Name
}

[void]$LightMake.WriteLine('$Ret = Invoke-Main $args')

[void]$LightMake.WriteLine('$ModuleList[-1..-($ModuleLsit.Count)] | Foreach-Object { Remove-Module $_ }')
$LightMake.Flush()
$LightMake.Close()