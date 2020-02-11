function Set-CIF3Config {
    <#
    .SYNOPSIS
        Set CIF3 module configuration.

    .DESCRIPTION
        Set CIF3 module configuration, and $CIF3 module variable.

        This data is used as the default Token and Uri for most commands.

        WARNING: Use this to store the token or uri on a filesystem at your own risk
                 Only supported on Windows systems, via the DPAPI

    .PARAMETER Token
        Specify a Token to use

    .PARAMETER EncryptToken
        If set to true, serializes token to disk via DPAPI (Windows only)

    .PARAMETER Uri
        Specify a Uri to use

    .PARAMETER Proxy
        Proxy to use with Invoke-RESTMethod

    .PARAMETER ForceVerbose
        If set to true, we allow verbose output that may include sensitive data

        *** WARNING ***
        If you set this to true, your CIF token will be visible as plain text in verbose output

    .PARAMETER NoVerifySsl
        If set to true, writes corresponding option in cif.yml file and doesn't verify SSL on remote uri
    
    .PARAMETER Path
        If specified, save config file to this file path.  Defaults to .cif.yml in the module folder on Windows, or .cif.yml in the user's home directory on Linux/macOS.

    .FUNCTIONALITY
        CIF - Collective Intelligence Framework
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Token,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Proxy,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool]$ForceVerbose,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool]$NoVerifySsl,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool]$EncryptToken,
        
        [string]$Path = $script:_CIF3Ymlpath
    )

    Process {

        switch ($PSBoundParameters.Keys) {
            'Uri' { $Script:CIF3.Uri = $Uri }
            'Token' { $Script:CIF3.Token = $Token }
            'Proxy' { $Script:CIF3.Proxy = $Proxy }
            'ForceVerbose' { $Script:CIF3.ForceVerbose = $ForceVerbose }
            'NoVerifySsl' { $Script:CIF3.NoVerifySsl = $NoVerifySsl }
        }

        function Encrypt {
            param([string]$String)
            if ($String -notlike '' -and $env:OS -eq 'Windows_NT' -and $EncryptToken -eq $true) {
                ConvertTo-SecureString -String $String -AsPlainText -Force | ConvertFrom-SecureString
            }
            # If we're not on Windows, just return the regular String value since it shouldn't be encrypted
            else { $String }
        }

        # Write the global variable and the yml
        # Use Ordered Dictionaries to maintain the order in the .cif.yml that is specified here
        $OrderedCIFSettings = New-Object ([System.Collections.Specialized.OrderedDictionary])
        $OrderedCIFSettings.Add("client", [ordered]@{
                "remote"        = "$($Script:CIF3.Uri)"
                "token"         = "$(Encrypt $Script:CIF3.Token)"
                "no_verify_ssl" = "$($Script:CIF3.NoVerifySsl)"
                "force_verbose" = "$($Script:CIF3.ForceVerbose)"
                "proxy"         = "$($Script:CIF3.Proxy)"
            })
    
        try {
            $OrderedCIFSettings | ConvertTo-Yaml -OutFile $Path -Force
            # Ugly hack to lower the case of 'True' and 'False' in the .cif.yml file
            # and eliminate empty double quotes
            (Get-Content -Path $Path) `
                -replace 'True', 'true' `
                -replace 'False', 'false' `
                -replace '""', '' | Set-Content -Path $Path
            Write-Verbose "Settings saved to $Path"
        }
        catch { Write-Warning "Error writing CIF3 config file: $_" }

    }

}