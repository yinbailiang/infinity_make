. .\infbuild.ps1
try {
    . .\infinity_make.ps1
}
catch {
    Write-BuildError "$($_.Exception.Message)"
    Write-BuildError "`n$($_.ScriptStackTrace)"
}