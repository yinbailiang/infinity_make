Set-SolutionName 'Test'

Add-Option 'UseToolChain' {
    Set-Default 'msvc'
}
Add-Option 'EnableException' {
    Set-Default $false
}
Set-Option 'EnableException' $true


Add-Project 'SimpileLib' {
    Set-Langauges 'c++26','c20'
    Set-Kind 'static'
    Set-Arch 'x64'
    Set-ToolChain 'msvc'
    Add-SourceFile 'lib\*.cpp'
}

Add-Project 'SimpileTest' {
    Set-Langauges 'c++26','c20'
    Add-Requires "SimpileLib"
    Set-Kind 'binary'
    Set-Arch 'x64'
    Set-ToolChain 'msvc'
    Add-SourceFile '*.cpp'
}