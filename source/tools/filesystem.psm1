##Module InfinityMake.Tool.FileSystem
function Expand-BuiltinResource([string]$DestinationPath) {
    $ResourceHashCodePath = Join-Path $DestinationPath 'builtin_resource_hash_code.json'
    if(Test-Path $ResourceHashCodePath -PathType Leaf){
        $ResourceHashCode = ConvertFrom-Json -InputObject (Get-Content -Path $ResourceHashCodePath -Raw) -AsHashtable
        if($ResourceHashCode.HashCode -eq $BuiltinResourceZipHash){
            return
        }
    }
    Remove-Item (Get-ChildItem $DestinationPath) -Recurse -Force
    Set-Content -Path $ResourceHashCodePath -Value (ConvertTo-Json -InputObject @{'HashCode' = $BuiltinResourceZipHash} -Compress) -NoNewline
    $ResourceZipPath = Join-Path $DestinationPath 'reource.zip'
    Set-Content -Path $ResourceZipPath -Value $BuiltinResourceZipContent -AsByteStream
    Expand-Archive -Path $ResourceZipPath -DestinationPath $DestinationPath -Force
    Remove-Item $ResourceZipPath
}

function Build-BaseFileSystem {
    $WorkDir = Get-Location
    $CacheDir = Join-Path $WorkDir '.infmake'
    if (-not (Test-Path -Path $CacheDir -PathType Container)) {
        $null = New-Item -Path $CacheDir -ItemType Directory
    }
    $ResoureDir = Join-Path $CacheDir 'resource'
    if(-not (Test-Path -Path $ResoureDir -PathType Container)){
        $null = New-Item -Path $ResoureDir -ItemType Directory
    }
    Expand-BuiltinResource $ResoureDir
    return @{
        'WorkDir' = $WorkDir
        'CacheDir' = $CacheDir
        'ResourceDir' = $ResoureDir
    }
}

$BaseFileSystem = Build-BaseFileSystem