##Module InfinityMake.Core.Solution
##Import InfinityMake.Tools

$SolutionTable = @{}

function Add-Solution([string]$Name, [scriptblock]$Define) {
    $Solution = @{}

    function Add-Project([string]$ProjectName, [scriptblock]$ProjectDefine) {
        $Project = @{}

        $ProjectBasicAPI = @{
            'Language'  = @{
                'Type' = 'Set'
                'Data' = [string]
            }
            'ToolChain' = @{
                'Type' = 'Set'
                'Data' = [string]
            }
            'Kind'      = @{
                'Type' = 'Set'
                'Data' = [string]
            }
            'Arch'      = @{
                'Type' = 'Set'
                'Data' = [string]
            }
            'SourceFiles' = @{
                'Type' = 'Add'
                'Data' = [string[]]
            }
            'Requires' = @{
                'Type' = 'Add'
                'Data' = [string[]]
            }
        }

        Invoke-Expression (Build-DataAPI 'Project' $ProjectBasicAPI)

        $ProjectDefine.Invoke()
        
        if (-not $Solution.ContainsKey('Projects')) {
            $Solution['Projects'] = @{}
        }
        $Solution['Projects'][$ProjectName] = $Project
    }

    $Define.Invoke()
    $SolutionTable[$Name] = $Solution
}