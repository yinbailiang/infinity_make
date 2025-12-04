##Module InfinityMake.Core.Platform
##Import InfinityMake.Tools


$PlatformTable = @{}

$PlatformAPI = @{
    'SupportHosts' = @{
        'Type' = 'Set'
        'Data' = [string[]]
    }
    'SupportArchs' = @{
        'Type' = 'Set'
        'Data' = [string[]]
    }
}

function Add-Platform([string]$Name,[scriptblock]$Define) {
    $Platform = @{}

    Invoke-Expression (Build-API 'Platform' $PlatformAPI)

    $Define.Invoke()

    $PlatformTable[$Name] = $Platform
}

Import-DynamicModule 'platform.windows'

[LogClient]::new([LogType]::LogDebug).OpenIndentationField{
    $PlatformTable | ConvertTo-Json -Depth 3
}