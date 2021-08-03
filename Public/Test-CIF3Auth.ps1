function Test-CIF3Auth {
    <#
    .SYNOPSIS
        Tests connectivity to the CIF API via token.
    .DESCRIPTION
        This cmdlet calls the CIF API /ping method to ensure CIF3 client is able to connect and authenticate to CIF API.
        By default, tests only read access. Use -VerifyWrite switch to test write token access.
    .EXAMPLE
        # Test connectivity with current session token
        PS C:\> Test-CIF3Auth
        
        # Test connectivity using a specified token
        PS C:\> Test-CIF3Auth -Token "0000111222333456789abcdef"

        # Test whether supplied token gives write access at CIF API.
        PS C:\> Test-CIF3Auth -VerifyWrite

    .OUTPUTS
        A Boolean value indicating whether the call passed/failed, or the response object from CIF instance's API.
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER VerfifyWrite
        Test whether token has write access to CIF instance API. Without this switch, read-only access is tested.
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning a boolean.
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/ping.py
    #>
    [CmdletBinding()]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [switch]$VerifyWrite,

        [switch]$Raw
    )

    begin {
        if ($VerifyWrite -eq $true) {
            $Uri += '/ping?write=1'
            $Token = Select-ClientToken -Token $Token -RequestType 'Write'
        }
        else {
            $Uri += '/ping'
            $Token = Select-ClientToken -Token $Token -RequestType 'Read'
        }
    }

    process {
        Write-Verbose 'Testing CIF API'

        $Params = @{
            Method  = 'GET'
            Uri     = $Uri
        }

        Write-Verbose 'Adding token to request'
        $Params.Token = $Token
        
        try {
            $Response = Send-CIF3Api @Params -ErrorAction Stop
        } catch {
            # 401 unauthorized gets thrown if token doesn't have access so catch to ret $false. Otherwise re-throw 
            # if raw is requested or in the event of any other error
            if (-not $_.Exception.Message -match '401' -or $Raw -eq $true) {
                throw $_.Exception
            }
        }
        
        if ($Raw) {
            return $Response
        } elseif ($Response.message -eq 'success' -or $Response.data.read -eq $true -or $Response.data.write -eq $true) {
                Write-Verbose 'Received response from CIF API'
                return $true
        } else {
            #Write-Error -Exception $_.Exception -Message "CIF API call succeeded, but responded with incorrect value: $_"
            return $false
        }
    }
}