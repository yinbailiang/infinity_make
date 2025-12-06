##Module InfinityMake.Tools.PreDefineds

$Script:Version = if ($null -ne $Script:Version) { $Script:Version } else { "UnknowVersion" }
$Script:DevMode = if ($null -ne $Script:DevMode) { $Script:DevMode } else { "Release" }