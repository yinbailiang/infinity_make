##Module APIBuilder.Test
##Import InfinityMake.Tools.APIBuilder

$TestAPI = @{
    'Language'    = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'ToolChain'   = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'Kind'        = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'Arch'        = @{
        'Type' = 'Set'
        'Data' = [string]
    }
    'SourceFiles' = @{
        'Type' = 'Add'
        'Data' = [string[]]
    }
    'Requires'    = @{
        'Type' = 'Add'
        'Data' = [string[]]
    }
}

Write-BuildLog "TestAPICode $([System.Environment]::NewLine)$((Build-API 'Test' $TestAPI))"