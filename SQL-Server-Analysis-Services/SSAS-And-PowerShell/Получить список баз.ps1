$loadInfo = [Reflection.Assembly]::LoadWithPartialName(“Microsoft.AnalysisServices”)

$connection = “localhost”
$server = New-Object Microsoft.AnalysisServices.Server
$server.connect($connection)

foreach ($d in $server.Databases )
{
    Write-Output (“Database: {0}, String {1}:” -f $d.Name, $d.DataSources.ConnectionString)        
}