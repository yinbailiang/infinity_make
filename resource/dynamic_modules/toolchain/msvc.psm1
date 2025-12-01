Add-ToolChain 'MSVC' {
    Set-Kind 'Standalone'
    Set-HomePage 'https://visualstudio.microsoft.com'
    Set-Description 'Microsoft Visual C/C++ Compiler'

    Set-SupportLanguages 'C','Cpp'

    Set-OnCheck {
        return $true
    }

    Set-OnLoad {
        param([hashtable]$Project)

        Add-Tool 'Compiler' @{
            'Path' = 'cl.exe'
            'RunEnv' = @{}
        }

        Add-Tools @{
            'Linker' = @{
                'Path' = 'link.exe'
                'RunEnv' = @{}
            }
        }
    }
}