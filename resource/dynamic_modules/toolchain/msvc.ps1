Add-ToolChain 'MSVC' {
    Set-HomePage 'https://visualstudio.microsoft.com'
    Set-Description 'Microsoft Visual C/C++ Compiler'

    Set-SupportLanguages 'C','Cpp'

    Set-OnCheck {
        return $true
    }

    Set-OnLoad {
        param([hashtable]$Project)
        Add-Tool 'SourceScaner' {

        }
        Add-Tool 'Compiler' {
            
        }
    }
}