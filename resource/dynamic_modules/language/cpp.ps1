Add-Language "Cpp" {
    Set-Structs @{
        'Project' = @{
            'Type' = [hashtable]
            'Description' = '项目的定义'
        }
        'Source' = @{
            'Type' = [string[]]
            'Description' = '源代码'
        }
        'Object' = @{
            'Type' = [string[]]
            'Description' = '对象文件'
        }
        'Binary' = @{
            'Type' = [string]
            'Description' = '可执行文件'
        }
        'StaticLib' = @{
            'Type' = [string]
            'Description' = '静态库'
        }
        'SharedLib' = @{
            'Type' = [string]
            'Description' = '动态库'
        }
    }

    Set-RequireTools @{
        'SourceSacner' = @{
            'Form' = 'Project'
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

    Set-ProjectKinds @{
        'Binary' = @{
            'BuildChain' = 'Project -> SourceScaner -> Compiler -> Linker'
        }
        'Static' = @{
            'BuildChain' = 'Project -> SourceScaner -> Compiler -> StaticArchiver'
        }
        'Shared' = @{
            'BuildChain' = 'Project -> SourceScaner -> Compiler -> SharedArchiver'
        }
    }
}