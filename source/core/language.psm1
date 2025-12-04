##Module InfinityMake.Core.Language
##Import InfinityMake.Tools

$LanguageAPI = @{
    'Structs'        = @{
        'Type' = 'Set'
        'Data' = [hashtable]
    }
    'RequireTools'   = @{
        'Type' = 'Set'
        'Data' = [hashtable]
    }
    'ProjectKinds' = @{
        'Type' = 'Set'
        'Data' = [hashtable]
    }
}

$LanguageTable = @{}
function Add-Language([string]$Name, [scriptblock]$Define) {
    $Language = @{}
    Invoke-Expression (Build-API 'Language' $LanguageAPI)

    $Define.Invoke()
    $LanguageTable[$Name] = $Language
}

Import-DynamicModule 'language.c'
Import-DynamicModule 'language.cpp'

[LogClient]::new([LogType]::LogDebug).OpenIndentationField{
    $LanguageTable | ConvertTo-Json -Depth 3
}