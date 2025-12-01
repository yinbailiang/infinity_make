Add-Platform 'Windows' {
    Set-Hosts 'Windows'
    Set-Archs 'x86', 'x64', 'arm', 'arm64', 'arm64ec'

    Set-Formats @{
        'Object' = '{0}.obj'
        'Static' = '{0}.lib'
        'Shared' = '{0}.dll'
        'Binary' = '{0}.exe'
        'Symbol' = '{0}.pdb'
    }
}