# Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue )

# Dot source the files
foreach ($Import in @($Public + $Private)) {
    try {
        . $Import.FullName
    } 
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

# Create / Read config
$Script:_CIF3YmlPath = Join-Path -Path "${env:HOMEDRIVE}${env:HOMEPATH}" -ChildPath '.cif.yml'
if (-not (Test-Path -Path $Script:_CIF3YmlPath -ErrorAction SilentlyContinue)) {
    try {
        Write-Warning "Did not find config file $($Script:_CIF3YmlPath), attempting to create"
        @{ client = @{
                remote        = $null
                token         = $null
                no_verify_ssl = $true
                force_verbose = $false
                proxy         = $null
            } 
        } | ConvertTo-Yaml -OutFile $($Script:_CIF3YmlPath) -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to create config file $($Script:_CIF3YmlPath): $_"
    }
}

#Initialize the config variable.
try {
    #Import the config
    $Script:CIF3 = $null
    $Script:CIF3 = Get-CIF3Config -Source YML -ErrorAction Stop
}
catch {
    Write-Warning "Error importing CIF3 config: $_"
}

