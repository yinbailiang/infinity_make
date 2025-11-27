##Module InfinityMake.ToolChains

[hashtable]$ToolChainRegistrar = @{}

$ToolChainRegistrar['msvc'] = {
    param([hashtable]$Project)
    $ToolChain = @{}
    $ToolChain['Envirnment'] = @{}
    $ToolChain['Compiler'] = @{
        'Path'       = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\cl.exe'
        'Flags'      = @('/std:c++latest')
        'Envirnment' = @{
            'INCLUDE' = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\include;C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\ATLMFC\include;C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\VS\include;C:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\ucrt;C:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\um;C:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\shared;C:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\winrt;C:\Program Files (x86)\Windows Kits\10\\include\10.0.26100.0\\cppwinrt'
            'LIBPATH' = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\ATLMFC\lib\x64;C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\lib\x64;C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\lib\x86\store\references;C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.26100.0;C:\Program Files (x86)\Windows Kits\10\References\10.0.26100.0;C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
            'LIB'     = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\ATLMFC\lib\x64;C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\lib\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\\lib\10.0.26100.0\\um\x64'
        }
    }
    $ToolChain['Assember'] = @{
        'Path'       = ''
        'Flags'      = @()
        'Envirnment' = @{}
    }
    $ToolChain['Archiver'] = @{
        'Path'       = ''
        'Flags'      = @()
        'Envirnment' = @{}
    }
    $ToolChain['Linker'] = @{
        'Path'       = ''
        'Flags'      = @()
        'Envirnment' = @{}
    }
    $ToolChain['ResourceCompiler'] = @{
        'Path'       = ''
        'Flags'      = @()
        'Envirnment' = @{}
    }
    return $ToolChain
}

function New-ProcessStartInfo {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [hashtable]$Envirnment
    )
    $StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $FilePath
    foreach ($Argument in $ArgumentList) {
        $StartInfo.ArgumentList.Add($Argument)
    }
    foreach ($Pair in $Envirnment.GetEnumerator()) {
        $StartInfo.Environment[$Pair.Key] = $Pair.Value
    }

    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true

    return $StartInfo
}

function Get-ToolChain([string]$Name, [hashtable]$Project) {
    Invoke-Command $ToolChainRegistrar[$Name] -ArgumentList $Project
}

function Invoke-Compiler([hashtable]$ToolChain, [string[]]$Flags) {
    $Proc = [System.Diagnostics.Process]::new()
    $Proc.StartInfo = New-ProcessStartInfo -FilePath $ToolChain['Compiler']['Path'] -ArgumentList ($Flags + $ToolChain['Compiler']['Flags']) -Envirnment $ToolChain['Compiler']['Envirnment']
    $Proc.Start()
    $Proc.WaitForExit()
    Write-Host $Proc.StandardOutput.ReadToEnd()
    Write-Host $Proc.StandardError.ReadToEnd()
}

$msvc = Get-ToolChain -Name 'msvc' -Project @{}
Invoke-Compiler -ToolChain $msvc -Flags @('test\\main.cpp')

function Invoke-Assembler([hashtable]$ToolChain, [string[]]$Flags) {

}

function Invoke-Archiver([hashtable]$ToolChain, [string[]]$Flags) {

}

function Invoke-Linker([hashtable]$ToolChain, [string[]]$Flags) {

}

function Invoke-ResourceCompiler([hashtable]$ToolChain, [string[]]$Flags) {

}