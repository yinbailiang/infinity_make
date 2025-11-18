[string]$WorkFolder = Get-Location
[string]$SourcePath = Join-Path $WorkFolder 'Source'
[string[]]$SourceFiles = Get-ChildItem -Path $SourcePath -Filter '*.psm1' -Recurse -File

function Get-IMModule([string]$SourceFile) {
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

$IMModuleMap = @{}
$SourceFiles | ForEach-Object {
    $Module = Get-IMModule $_
    $IMModuleMap[$Module.Name] = @{
        'Requires' = $Module.Requires
        'Code'     = $Module.Code
    }
}
$InfinityMakeFile = Join-Path $WorkFolder 'infinity_make.ps1'
$SourceData = $IMModuleMap | ConvertTo-Json -Depth 5 -Compress

Set-Content $InfinityMakeFile ("{0} = ConvertFrom-Json -AsHashtable -InputObject '{1}'" -f '$IMModules', $SourceData)
Add-Content $InfinityMakeFile (Get-Content '.\template.ps1' -Raw)