##Module InfinityMake.Core.Solution

$SolutionTable = @{}

function Add-SolutionFormFile([string]$Name,[scriptblock]$Define) {
    $Solution = @{}

    function Add-Option([string]$Name, [scriptblock]$Code) {
        $Option = @{}
        
        function Set-Default($Value) {
            $Option['Default'] = $Value
            $Option['Value'] = $Value
        }

        Invoke-Command $Code

        if (-not $Solution.ContainsKey('Options')) {
            $Solution['Options'] = @{}
        }
        $Solution['Options'][$Name] = $Option
    }

    function Get-ToolChain([string]$Name) {
        
    }

    function Set-Option([string]$Name, $Value) {
        if (-not $Solution['Options'].ContainsKey($Name)) {
            Write-Error "CanNotFindOption<$Name>"
            return
        }
        $Solution['Options'][$Name]['Value'] = $Value
    }

    function Get-Option([string]$Name) {
        if (-not $Solution['Options'].ContainsKey($Name)) {
            Write-Error "CanNotFindOption<$Name>"
            return
        }
        return $Solution['Options'][$Name]['Value']
    }


    function Add-Project([string]$Name, [scriptblock]$Code) {
        $Project = @{
            'Name' = $Name
        }

        function Set-ToolChain([string]$ToolChain) {
            $Project['ToolChain'] = $ToolChain
        }
        function Set-Langauges([string[]]$Languages) {
            $Project['Languages'] = $Languages
        }
        function Set-Kind([string]$Kind) {
            $Project['Kind'] = $Kind
        }
        function Set-Arch([string]$Arch) {
            $Project['Arch'] = $Arch
        }
        function Set-Plat([string]$Plat) {
            $Project['Plat'] = $Plat
        }
        function Add-Requires([string[]]$Requires) {
            if (-not $Project.ContainsKey('Requires')) {
                $Project['Requires'] = @()
            }
            $Project['Requires'] += $Requires
        }
        function Add-SourceFile([string[]]$SourceFiles) {
            if ($null -eq $Project['SourceFiles']) {
                $Project['SourceFiles'] = $SourceFiles
            }
            else {
                $Project['SourceFiles'] += $SourceFiles
            }
        }

        Invoke-Command $Code

        if (-not $Solution.ContainsKey('Projects')) {
            $Solution['Projects'] = @()
        }
        $Solution['Projects'] += $Project
    }

    $Define.Invoke()

    $SolutionTable[$Name] = $Solution
}