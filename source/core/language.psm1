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
    'SupportTargets' = @{
        'Type' = 'Set'
        'Data' = [hashtable]
    }
}

$LanguageTable = @{}
function Add-Language([string]$Name, [scriptblock]$Define) {
    $Language = @{}
    Invoke-Expression (Build-DataAPI 'Language' $LanguageAPI)

    $Define.Invoke()
    $LanguageTable[$Name] = $Language
}

Import-DynamicModule 'language.c'

$LanguageTbaleLoger = [LogClient]::new([LogType]::LogDebug)
$LanguageTbaleLoger.Write(($LanguageTable | ConvertTo-Json -Depth 3))