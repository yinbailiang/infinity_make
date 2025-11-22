##Module InfinityMake.Builder
##Import InfinityMake.FileSystem

$Plats = @{}
function Get-Plat([string]$Name) {
    return Invoke-Command $Plats[$Name]
}

$Plats['windows'] = {

}
$Plats['mingw-w64'] = {

}

$ToolChains = @{}
function Get-ToolChain([string]$Name) {
    return $ToolChains[$Name]
}

$ToolChains['msvc'] = {
    param([hashtable]$Project, [hashtable]$FileSystem)

    $VSInstanceList = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs
    $VSInstance = if ($VSInstanceList.Count -gt 1) {
        Write-Log LogDebug ('MutipleVSInstance')
        foreach ($Instance in $VSInstanceList) {
            Write-Log LogDebug ($Instance.ElementName)
        }
        $VSInstanceList[0]
    }
    else {
        $VSInstanceList[0]
    }
    $DevShellModulePath = Join-Path $VSInstance.InstallLocation "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

    Import-Module -Name $DevShellModulePath
    switch ($Project.Arch) {
        'x86' {
            Enter-VsDevShell -SkipAutomaticLocation -InstanceId $VSInstance.IdentifyingNumber -Arch x86 -DevCmdArguments '-no_logo'
        }
        'x64' {
            Enter-VsDevShell -SkipAutomaticLocation -InstanceId $VSInstance.IdentifyingNumber -Arch amd64 -DevCmdArguments '-no_logo'
        }
        'amd64' {
            Enter-VsDevShell -SkipAutomaticLocation -InstanceId $VSInstance.IdentifyingNumber -Arch amd64 -DevCmdArguments '-no_logo'
        }
        'arm' {
            Enter-VsDevShell -SkipAutomaticLocation -InstanceId $VSInstance.IdentifyingNumber -Arch arm -DevCmdArguments '-no_logo'
        }
        'arm64' {
            Enter-VsDevShell -SkipAutomaticLocation -InstanceId $VSInstance.IdentifyingNumber -Arch arm64 -DevCmdArguments '-no_logo'
        }
    }

    $SourceFiles = @()
    foreach ($Filter in $Project.SourceFiles) {
        $SourceFiles += Get-ChildItem -Path $FileSystem.SolutionFileSystem.WorkDir -Filter $Filter
    }
    $ObjsList = [System.Collections.Generic.List[string]]::new()
    $ProcessSet = [System.Collections.Generic.HashSet[System.Diagnostics.Process]]::new()
    foreach ($Path in $SourceFiles) {
        $CompileFlags = @(('"{0}"' -f $Path), '/c', '/nologo')
        $ObjPath = Join-Path $FileSystem.ObjsDir ($Path.BaseName + '.obj')
        [void]$ObjsList.Add($ObjPath)
        $CompileFlags += ('/Fo"{0}"' -f $ObjPath.Replace('\', '\\'))
        
        Write-Host ("CompileFlags<$CompileFlags>")
        
        $ProcStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcStartInfo.FileName = (Get-Command 'cl').Path
        $ProcStartInfo.Arguments = $CompileFlags

        $ProcStartInfo.CreateNoWindow = $false
        $ProcStartInfo.UseShellExecute = $false

        $ProcStartInfo.RedirectStandardError = $true
        $ProcStartInfo.RedirectStandardOutput = $true

        $Proc = New-Object System.Diagnostics.Process
        $Proc.StartInfo = $ProcStartInfo
        [void]$Proc.Start()
        [void]$ProcessSet.Add($Proc)
    }
    foreach ($Proc in $ProcessSet) {
        [void]$Proc.WaitForExit()
    }
    switch ($Project.Kind) {
        'static' {
            $ResultPath = Join-Path $FileSystem.BuildDir ("{0}.lib" -f $Project.Name)
            $LinkFlags = $ObjsList.ToArray()
            $LinkFlags += '/nologo'
            $LinkFlags += '/OUT:"{0}"' -f $ResultPath.Replace('\','\\')
            Write-Host $LinkFlags
            $ProcStartInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcStartInfo.FileName = (Get-Command 'lib').Path
            $ProcStartInfo.Arguments = $LinkFlags

            $ProcStartInfo.CreateNoWindow = $false
            $ProcStartInfo.UseShellExecute = $false

            $ProcStartInfo.RedirectStandardError = $true
            $ProcStartInfo.RedirectStandardOutput = $true

            $Proc = New-Object System.Diagnostics.Process
            $Proc.StartInfo = $ProcStartInfo
            [void]$Proc.Start()
            [void]$Proc.WaitForExit()
            $Proc.StandardError.ReadToEnd() | Write-Host
            $Proc.StandardOutput.ReadToEnd() | Write-Host
        }
        'binary' {
            
        }
    }
}

$ToolChains['llvm'] = {
    param([hashtable]$Project, [hashtable]$FileSystem)
            
}


function Build-Project([hashtable]$Project, [hashtable]$SolutionFileSystem) {
    $FileSystem = Build-ProjectFileSystem $Project $SolutionFileSystem
    Pwsh -Command $ToolChains[$Project.ToolChain] -Args $Project, $FileSystem
}

function Build-Solution([hashtable]$Solution) {
    $SolutionFileSystem = Build-SolutionFileSystem $Solution (Get-WorkDir)

    $ProjectBuilded = [System.Collections.Generic.HashSet[string]]::new()
    $ProjectBuilding = [System.Collections.Generic.HashSet[string]]::new()

    $ProjectNameMap = @{}
    foreach ($Project in $Solution.Projects) {
        $ProjectNameMap[$Project.Name] = $Project
    }
    function Invoke-BuildProject([string]$ProjectName) {
        if ($ProjectBuilded.Contains($ProjectName)) {
            Write-Log LogDebug "<$ProjectName>IsBuilded"
            return
        }
        if ($ProjectBuilding.Contains($ProjectName)) {
            foreach ($Name in $ProjectBuilding) {
                Write-Log LogErr "CircularDependencyModule<$Name>"
            }
        }
        [void]$ProjectBuilding.Add($ProjectName)
        foreach ($RequireProjectName in $ProjectNameMap[$ProjectName].Requires) {
            Invoke-BuildProject $RequireProjectName
        }
        Write-Log LogInfo "BuildProject<$ProjectName>"
        Build-Project $ProjectNameMap[$ProjectName] $SolutionFileSystem
        [void]$ProjectBuilding.Remove($ProjectName)
        [void]$ProjectBuilded.Add($ProjectName)
    }

    foreach ($ProjectName in $ProjectNameMap.Keys) {
        Invoke-BuildProject $ProjectName
    }
}