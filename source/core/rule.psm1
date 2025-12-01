##Module InfinityMake.Core.Rule

$RuleTable = @{}

function Add-Rule([string]$Name,[scriptblock]$Define){
    $Rule = @{}

    function Set-OnLoad {
        
    }

    
    $Define.Invoke()
    $RuleTable[$Name] = $Rule
}