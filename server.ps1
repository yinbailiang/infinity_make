# Create (and open) a new runspace
$rs = [runspacefactory]::CreateRunspace()
$rs.Open()

$pipe = $rs.CreatePipeline()
$pipe.Commands.AddScript({
    Get-Location
})
$res = $pipe.Invoke()
foreach($line in $res){
    Write-Host $line
}
$rs.Close()