##Module InfinityMake.Core.ToolChain

$ToolChainTable = @{}

$ToolChainAPI = @{
    'HomePage' = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'Description' = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'SupportLanguages' = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'OnCheck' = @{
        'Type' = 'Set'
        'Data' = [scriptblock]
    }
    'OnLoad' = @{
        'Type' = 'Set'
        'Data' = [scriptblock]
    }
}

function Add-ToolChain([string]$Name,[scriptblock]$Define) {
    $ToolChain = @{}

    Invoke-Expression (Build-API 'ToolChain' $ToolChainAPI)

    $Define.Invoke()
    $ToolChainTable[$Name] = $ToolChain
}

Import-DynamicModule 'toolchain.msvc'

[LogClient]::new([LogType]::LogDebug).OpenIndentationField{
    $ToolChainTable | ConvertTo-Json -Depth 2
}