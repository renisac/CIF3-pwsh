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
            try {
                $SecureString = ConvertTo-SecureString $String -ErrorAction Stop
        
                if  ($SecureString -is [System.Security.SecureString]) {
                    [System.Runtime.InteropServices.marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.marshal]::SecureStringToBSTR(
                            $SecureString))
                }
            }
            catch {
                # If not a SecureString, just return the regular String value
                return $String
            }
        }
        $TempObj = Get-Content -Path $Path -Raw | ConvertFrom-Yaml | Select-Object -Property `
            @{l = 'Proxy'; e = { $_.client.proxy } },
            @{l = 'Uri'; e = { Decrypt $_.client.remote } },
            @{l = 'Token'; e = { Decrypt $_.client.token } },
            @{l = 'ReadToken'; e = { Decrypt $_.client.read_token } },
            @{l = 'WriteToken'; e = { Decrypt $_.client.write_token } },
            @{l = 'ForceVerbose'; e = { $_.client.force_verbose } },
            @{l = 'NoVerifySsl'; e = { $_.client.no_verify_ssl } }

        # yml file can use 'token' or 'read_token' as name; if no 'token' property, look for 'read_token'
        if ($null -eq $TempObj.Token -and $null -ne $TempObj.ReadToken) {
            $TempObj.Token = $TempObj.ReadToken
        }
        # backfill ReadToken prop if it's empty
        if ($null -ne $TempObj.Token -and $null -eq $TempObj.ReadToken) {
            $TempObj.ReadToken = $TempObj.Token
        }

        # Nice oneliner to convert PSCustomObject to Hashtable: https://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable
        $TempObj.PSObject.Properties | ForEach-Object -Begin { $h = @{ } } -Process { $h."$($_.Name)" = $_.Value } -End { $h } 
    }

}