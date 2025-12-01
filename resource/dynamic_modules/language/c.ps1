Add-Language "C" {
    Set-Formats @{
        'Source' = @{
            'Type' = [string[]]
        }
        'Object' = @{
            'Type' = [string[]]
        }
    }

    Set-RequireTools @{
        'SourceSacner' = @{
            'Form' = 'Project' #Predefine
            'To' = 'Source'
        }
        'Compiler' = @{
            'Form' = 'Source'
            'To' = 'Object'
        }
        'Link' = @{
            'Form' = 'Object'
            'To' = 'Binary'
        }
        'StaticArchiver' = @{
            'Form' = 'Object'
            'To' = 'StaticLib'
        }
        'SharedArchiver' = @{
            'Form' = 'Object'
            'To' = 'SharedLib'
        }
    }

    Set-SupportTargets @{
        'Binary' = @{
            'BuildChain' = 'Project -> Source -> Compile -> Link'
        }
        'Static' = @{
            'BuildChain' = 'Project -> Source -> Compile -> Static'
        }
        'Shared' = @{
            'BuildChain' = 'Project -> Source -> Compile -> Shared'
        }
    }

    Set-BuildProcess 'Source' {
        param([hashtable]$ToolSet,[hashtable]$Project)

    }
    Set-BuildProcess 'Compile' {
        param([hashtable]$ToolSet, [string[]]$SourceList)
        $ObjectList = @()
        foreach($Source in $SourceList){
            $ObjectList += $ToolSet['Compiler'].Invoke($Source)
        }
        return $ObjectList
    }
    Set-BuildProcess 'Link' {
        param([hashtable]$ToolSet, [string[]]$ObjectList)
        $Binary = $ToolSet['Linker'].Invoke($ObjectList)
        return $Binary
    }
    Set-BuildProcess 'Static' {
        param([hashtable]$ToolSet, [string[]]$ObjectList)
        $Binary = $ToolSet['StaticArchiver'].Invoke($ObjectList)
        return $Binary
    }
    Set-BuildProcess 'Shared' {
        param([hashtable]$ToolSet, [string[]]$ObjectList)
        $Binary = $ToolSet['SharedArchiver'].Invoke($ObjectList)
        return $Binary
    }
}