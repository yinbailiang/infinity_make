[string]$WorkFolder = Get-Location
[string]$CacheFolder = Join-Path $WorkFolder ".buildcache"

[hashtable]$BuildConfig = Get-Content (Join-Path $WorkFolder 'buildconfig.json') -Raw | ConvertFrom-Json -AsHashtable


[string[]]$SourceFiles = @()
foreach ($Filter in $BuildConfig.SourcePath) {
    $SourceFiles += Get-ChildItem -Path $WorkFolder -Filter $Filter
}

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

$ScriptFileStream = [System.IO.StreamWriter]::new($BuildConfig.Name + '.ps1')
$ModuleLoaded = [System.Collections.Generic.HashSet[string]]::new()
$ModuleLoading = [System.Collections.Generic.HashSet[string]]::new()


[string[]]$ResourceFiles = @()
foreach ($Filter in $BuildConfig.ResourcePath) {
    $ResourceFiles += Get-ChildItem -Path $WorkFolder -Filter $Filter
}

$ResourceZipPath = Join-Path $CacheFolder 'resource.zip'
Compress-Archive -Path $ResourceFiles -DestinationPath $ResourceZipPath -CompressionLevel Optimal -Force
$ResourceZipHash = Get-FileHash -Path $ResourceZipPath -Algorithm SHA256
[void]$ScriptFileStream.WriteLine('$BuiltinResourceZipHash = "{0}"' -f $ResourceZipHash.Hash)

$ResourceZipFileStream = [System.IO.FileStream]::new($ResourceZipPath, [System.IO.FileMode]::Open)
$ResourceZipData = [byte[]]::new($ResourceZipFileStream.Length)
[void]$ResourceZipFileStream.Read($ResourceZipData, 0, $ResourceZipFileStream.Length)
$ResourceZipFileStream.Close()


$ResourceZipBase64Data = [System.Convert]::ToBase64String($ResourceZipData)
[void]$ScriptFileStream.Write('$BuiltinResourceZipContent = [System.Convert]::FromBase64String("')
[void]$ScriptFileStream.Write($ResourceZipBase64Data)
[void]$ScriptFileStream.WriteLine('")')

foreach ($Name in $BuildConfig.PreDefine.Keys) {
    if ($BuildConfig.PreDefine[$Name].GetType() -eq [string]) {
        [void]$ScriptFileStream.WriteLine('${0} = "{1}"' -f ($Name, $BuildConfig.PreDefine[$Name]))
    }
    else {
        [void]$ScriptFileStream.WriteLine('${0} = {1}' -f ($Name, $BuildConfig.PreDefine[$Name]))
    }
}

function Add-Module($ModuleName) {
    if ($ModuleLoaded.Contains($ModuleName)) {
        return
    }
    if ($ModuleLoading.Contains($ModuleName)) {
        foreach ($Name in $ModuleLoading) {
            Write-Error "CircularDependencyModule<$Name>“
        }
        return
    }
    [void]$ModuleLoading.Add($ModuleName)
    foreach ($RequireModuleName in $ModuleMap[$ModuleName].Requires) {
        Add-Module $RequireModuleName
    }
    [void]$ScriptFileStream.Write($ModuleMap[$ModuleName].Code)
    [void]$ModuleLoading.Remove($ModuleName)
    [void]$ModuleLoaded.Add($ModuleName)
}

foreach ($Name in $ModuleMap.Keys) {
    Add-Module $Name
}


[void]$ScriptFileStream.WriteLine('$Ret = Invoke-Main $args')

$ScriptFileStream.Flush()
$ScriptFileStream.Close()