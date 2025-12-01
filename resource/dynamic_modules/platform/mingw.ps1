Add-Platform 'Mingw' {
    Set-Hosts 'MacOSX','Linux','Windows','BSD'
    Set-Archs 'x86','x64','arm','arm64'

    Set-Formats @{
        'Object' = '{0}.obj'
        'Static' = 'lib{0}.a'
        'Shared' = 'lib{0}.dll'
        'Binary' = '{0}.exe'
        'Symbol' = '{0}.pdb'
    }

    Set-ToolChains 'llvm'
}