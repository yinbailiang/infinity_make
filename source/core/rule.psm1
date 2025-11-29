##Module InfinityMake.Core.Rule

$RuleTable = @{}

function Add-Rule([string]$Name,[scriptblock]$Define){
    $Rule = @{}



    
    $Define.Invoke()
    $RuleTable[$Name] = $Rule
}