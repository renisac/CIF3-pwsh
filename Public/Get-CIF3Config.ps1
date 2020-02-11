function Get-CIF3Config {
    <#
    .SYNOPSIS
        Get CIF3 module configuration.

    .DESCRIPTION
        Get CIF3 module configuration

    .PARAMETER Source
        Get the config data from either...

            CIF3:    the live module variable used for command defaults
            YML:    the serialized .cif.yml that loads when importing the module

        Defaults to CIF3

    .PARAMETER Path
        If specified, read config from this YML file.

        Defaults to .cif.yml in the user's home directory.

    .FUNCTIONALITY
        CIF - Collective Intelligence Framework
    #>
    [CmdletBinding(DefaultParameterSetName = 'Source')]
    param(
        [Parameter(ParameterSetName = 'Source')]
        [ValidateSet("CIF3", "YML")]
        $Source = "CIF3",

        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'Source')]
        $Path = $Script:_CIF3Ymlpath
    )

    if ($PSCmdlet.ParameterSetName -eq 'Source' -and $Source -eq "CIF3" -and -not $PSBoundParameters.ContainsKey('Path')) {
        $Script:CIF3
    }
    else {
        function Decrypt {
            param($String)
            if ($String -is [System.Security.SecureString]) {
                [System.Runtime.InteropServices.marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.marshal]::SecureStringToBSTR(
                        $String))
            }
            # If not a SecureString, just return the regular String value
            else { $String }
        }
        $TempObj = Get-Content -Path $Path -Raw | ConvertFrom-Yaml | Select-Object -Property `
            @{l = 'Proxy'; e = { $_.client.proxy } },
            @{l = 'Uri'; e = { Decrypt $_.client.remote } },
            @{l = 'Token'; e = { Decrypt $_.client.token } },
            @{l = 'ForceVerbose'; e = { $_.client.force_verbose } },
            @{l = 'NoVerifySsl'; e = { $_.client.no_verify_ssl } }

        # Nice oneliner to convert PSCustomObject to Hashtable: https://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable
        $TempObj.PSObject.Properties | ForEach-Object -Begin { $h = @{ } } -Process { $h."$($_.Name)" = $_.Value } -End { $h } 
    }

}