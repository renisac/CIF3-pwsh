Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

$ReleaseNotes = $env:RELEASE_NOTES
$ModuleVersion = ($env:RELEASE_VERSION) -replace 'v',''
Write-Host "ModuleVersion: $ModuleVersion"

$ManifestPath = Resolve-Path -Path "*\*.psd1"
Write-Host "Manifest Path: $ManifestPath"

Update-ModuleManifest -ReleaseNotes $ReleaseNotes -Path $ManifestPath.Path -ModuleVersion $ModuleVersion -Verbose

$ModuleFilePath = Resolve-Path -Path "*\*.psm1"
Write-Host "Module File Path: $ModuleFilePath"

$ModulePath = Split-Path -Parent $ModuleFilePath
Write-Host "Module Path: $ModulePath"

$NuGetApiKey = $env:PSGALLERY_TOKEN

try{
    Publish-Module -Path $ModulePath -NuGetApiKey $NuGetApiKey -ErrorAction Stop -Force -Verbose
    Write-Host "The PowerShell Module version $ModuleVersion has been published to the PowerShell Gallery!"
}
catch {
    throw $_
}
