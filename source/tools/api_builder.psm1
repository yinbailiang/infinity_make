##Module InfinityMake.Tools.APIBuilder

$SetTemplate = @'
function Set-{0}([{1}]${0}) {{
    ${2}['{0}'] = ${0}
}}
'@# 0 = Name, 1 = Type, 2 = DataTable

$AddTemplate = @'
function Add-{0}([{1}]${0}) {{
    if(-not ${2}.ContainsKey('{0}')){{
        ${2}['{0}'] = ${0}
        return
    }}
    ${2}['{0}'] += ${0}
}}
'@# 0 = Name, 1 = Type, 2 = DataTable

function Build-DataAPI([string]$DataTableName,[hashtable]$APIDefine) {
    $Code = ''
    foreach($Pair in $APIDefine.GetEnumerator()){
        switch($Pair.Value['Type']){
            'Set'{
                $Code += $SetTemplate -f $Pair.Key,$Pair.Value['Data'],$DataTableName
            }
            'Add'{
                $Code += $AddTemplate -f $Pair.Key,$Pair.Value['Data'],$DataTableName
            }
        }
    }
    return $Code
}