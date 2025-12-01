Add-Solution 'SimpleSolution' {
    Add-Project 'SimpileLib' {
        Set-Plat 'Windows'
        Set-Langauge 'Cpp'
        Set-ToolChain 'MSVC'
        Set-Kind 'Static'
        Set-Arch 'x64'
        Add-SourceFile 'test/lib/*.cpp'
    }


    Add-Project 'SimpileTest' {
        Set-Plat 'Windows'
        Set-Langauge 'Cpp'
        Set-ToolChain 'MSVC'
        Add-Requires "SimpileLib"
        Set-Kind 'Binary'
        Set-Arch 'x64'
        Add-SourceFile 'test/*.cpp'
    }
}