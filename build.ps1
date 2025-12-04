function Write-BuildLog([string]$Text) {
    Write-Host "[Build]$($Text)" -ForegroundColor Cyan
}
function Write-BuildWorn([string]$Text) {
    Write-Host "[Build]$($Text)" -ForegroundColor Yellow
}

[string]$WorkFolder = Get-Location
[string]$CacheFolder = Join-Path $WorkFolder ".buildcache"
Write-BuildLog "WorkFolder $($WorkFolder)"
Write-BuildLog "CacheFolder $($CacheFolder)"

[hashtable]$BuildConfig = Get-Content (Join-Path $WorkFolder 'buildconfig.json') -Raw | ConvertFrom-Json -AsHashtable
Write-BuildLog "BuildConfig $([System.Environment]::NewLine)$($BuildConfig | ConvertTo-Json -Depth 5)"

function Find-Files ([string[]]$Filters) {
    $Files = @()
    foreach ($Filter in $Filters) {
        $Files += Get-ChildItem -Path $WorkFolder -Filter $Filter
    }
    return $Files
}
function Read-Module([string]$SourceFile) {
    Write-BuildLog "Read-Module $($SourceFile)"
    $Code = Get-Content $SourceFile
    $Module = @{
        'Name'     = $null
        'Requires' = @()
        'Code'     = ''
    }
    $Index = 0
    foreach ($Line in $Code) {
        $Index++
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
                Write-BuildWorn "UnknowPreProcessCommand $($Line)"
                Write-BuildWorn "->$($SourceFile)"
                Write-BuildWorn "->Line $($Index)"
            }
        }
    }
    return $Module
}
function Build-ModuleMap([string[]]$ModuleFiles) {
    $ModuleMap = @{}
    foreach ($File in $ModuleFiles) {
        $Module = Read-Module $File
        $ModuleMap[$Module.Name] = @{
            'Requires' = $Module.Requires
            'Code'     = $Module.Code
        }
    }
    return $ModuleMap
}
function Build-Module([string[]]$ModuleNameList, [hashtable]$ModuleMap) {
    $ModuleCode = [System.Collections.ArrayList]::new();
    $ModuleLoaded = [System.Collections.Generic.HashSet[string]]::new()
    $ModuleLoading = [System.Collections.Generic.HashSet[string]]::new()
    function Build-Module-Impl($ModuleName) {
        if (-not $ModuleMap.ContainsKey($ModuleName)) {
            Write-Error "CanNotFindModule $ModuleName"
            return
        }
        if ($ModuleLoaded.Contains($ModuleName)) {
            return
        }
        if ($ModuleLoading.Contains($ModuleName)) {
            foreach ($Name in $ModuleLoading) {
                Write-Error "CircularDependencyModule $Name“
            }
            return
        }
        [void]$ModuleLoading.Add($ModuleName)
        foreach ($RequireModuleName in $ModuleMap[$ModuleName].Requires) {
            Build-Module-Impl $RequireModuleName
        }
        Write-BuildLog "Build-Module-Impl $($ModuleName)"
        [void]$ModuleCode.Add($ModuleMap[$ModuleName].Code)
        [void]$ModuleLoading.Remove($ModuleName)
        [void]$ModuleLoaded.Add($ModuleName)
    }

    foreach ($Name in $ModuleNameList) {
        Build-Module-Impl $Name
    }
    return $ModuleCode -join [System.Environment]::NewLine
}
function Build-AllModule([hashtable]$ModuleMap) {
    $ModuleNameList = $ModuleMap.Keys | ForEach-Object { $_ }
    return Build-Module $ModuleNameList $ModuleMap
}

function Invoke-Test([string]$TestFile,[hashtable]$ModuleMap) {
    $TestModule = Read-Module $TestFile
    Write-BuildLog "TestName $($TestModule.Name)"
    $TestCode = '$InTest = $true'
    $TestCode += Build-Module $TestModule.Requires $ModuleMap
    $TestCode += $TestModule.Code
    {
        Invoke-Expression $TestCode
    }.Invoke()
}

[string[]]$SourceFiles = Find-Files $BuildConfig.SourcePath
Write-BuildLog "SourceFiles $([System.Environment]::NewLine)$($SourceFiles | ConvertTo-Json)"
[hashtable]$ModuleMap = Build-ModuleMap $SourceFiles

[string[]]$TestFiles = Find-Files $BuildConfig.TestPath
Write-BuildLog "TestFiles $([System.Environment]::NewLine)$($TestFiles | ConvertTo-Json)"
Write-BuildLog "RunTest-----------------------------------------------------------------"
$TestFiles | ForEach-Object {
    $Test = Invoke-Test $_ $ModuleMap
}
Write-BuildLog "TestFinish--------------------------------------------------------------"

function Compress-ResourceFiles([string[]]$ResourceFiles) {
    $ResourceZipPath = Join-Path $CacheFolder 'resource.zip'
    Compress-Archive -Path $ResourceFiles -DestinationPath $ResourceZipPath -CompressionLevel Optimal -Force
    $ResourceZipHash = Get-FileHash -Path $ResourceZipPath -Algorithm SHA256
    Write-BuildLog "ResourceZipHash $($ResourceZipHash.Algorithm) $($ResourceZipHash.Hash)"

    $ResourceZipFileStream = [System.IO.FileStream]::new($ResourceZipPath, [System.IO.FileMode]::Open)
    $ResourceZipData = [byte[]]::new($ResourceZipFileStream.Length)
    [void]$ResourceZipFileStream.Read($ResourceZipData, 0, $ResourceZipFileStream.Length)
    $ResourceZipFileStream.Close()

    $ResourceZipBase64Data = [System.Convert]::ToBase64String($ResourceZipData)
    return ('$BuiltinResourceZipHash = "{0}"' -f $ResourceZipHash.Hash) + [System.Environment]::NewLine + '$BuiltinResourceZipContent = [System.Convert]::FromBase64String("' + $ResourceZipBase64Data + '")'
}

function Build-PreDefines([hashtable]$PreDefines) {
    $Code = [System.Collections.ArrayList]::new()
    foreach ($Name in $PreDefines.Keys) {
        if ($PreDefines[$Name].GetType() -eq [string]) {
            $Code += ('${0} = "{1}"' -f ($Name, $PreDefines[$Name]))
        }
        else {
            $Code += ('${0} = {1}' -f ($Name, $PreDefines[$Name]))
        }
    }
    return $Code -join [System.Environment]::NewLine
}


$ScriptFileStream = [System.IO.StreamWriter]::new($BuildConfig.Name + '.ps1')

[string[]]$ResourceFiles = Find-Files $BuildConfig.ResourcePath
Write-BuildLog "ResourceFiles $([System.Environment]::NewLine)$($ResourceFiles | ConvertTo-Json)"
$ScriptFileStream.WriteLine((Compress-ResourceFiles $ResourceFiles))

$PreDefineCode = (Build-PreDefines $BuildConfig.PreDefine)
Write-BuildLog "PreDefineCode $([System.Environment]::NewLine)$($PreDefineCode)"
$ScriptFileStream.WriteLine($PreDefineCode)

[void]$ScriptFileStream.WriteLine((Build-AllModule $ModuleMap))

[void]$ScriptFileStream.WriteLine('$Ret = Invoke-Main $args')

$ScriptFileStream.Flush()
$ScriptFileStream.Close()