function Select-ClientToken {
    # helper function that selects the appropriate token for the client action
    # read options should use 'read_token' if available
    # write options should use 'write_token' if available
    # otherwise default to 'token'
    param (
        [Parameter(Mandatory = $true)]  
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Read', 'Write')]
        [string]$RequestType = "Read"
    )

    if ($Token -ne $Script:CIF3.Token) {
        # $Token defaults to $Script:CIF3.Token in the public functions
        # use explicitly provided token from the public function if provided
        Write-Verbose "Selecting explicitly passed token"
        return $Token
    }
    else {
        if ($Script:CIF3.ReadToken -and $RequestType -eq "Read") {
            # use the read token only if token is not configured
            Write-Verbose "Selecting read_token"
            return $Script:CIF3.ReadToken
        }
        elseif ($Script:CIF3.WriteToken -and $RequestType -eq "Write") {
            # use the write token if configured
            Write-Verbose "Selecting write_token"
            return $Script:CIF3.WriteToken
        }
        else {
            Write-Verbose "Selecting token"
            return $Script:CIF3.Token
        }
    }
}