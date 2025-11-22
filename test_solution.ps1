Set-SolutionName 'SimpleSolution'

Add-Project 'SimpileLib' {
    Set-Langauges 'c++26','c20'
    Set-Kind 'static'
    Set-Arch 'x64'
    Set-ToolChain 'msvc'
    Set-Plat 'windows'
    Add-SourceFile 'test/lib/*.cpp'
}

Add-Project 'SimpileLibx86' {
    Set-Langauges 'c++26','c20'
    Set-Kind 'static'
    Set-Arch 'x86'
    Set-ToolChain 'msvc'
    Set-Plat 'windows'
    Add-SourceFile 'test/lib/*.cpp'
}

Add-Project 'SimpileTest' {
    Set-Langauges 'c++26','c20'
    Add-Requires "SimpileLib"
    Set-Kind 'binary'
    Set-Arch 'x64'
    Set-ToolChain 'msvc'
    Set-Plat 'windows'
    Add-SourceFile 'test/*.cpp'
}