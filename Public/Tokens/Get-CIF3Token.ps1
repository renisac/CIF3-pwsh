function Get-CIF3Token {
    <#
    .SYNOPSIS
        Gets list of tokens from CIF3 API.
    .DESCRIPTION
        This cmdlet calls the CIF API /tokens method to list all available tokens on the CIF instance.
    .EXAMPLE
        # Get token list with current session token
        PS C:\> Get-CIF3Token
        
        # Get token list using a specified token
        PS C:\> Get-CIF3Token -Token 0000111222333456789abcdef

        # Get token list using a specified CIF API URI.
        PS C:\> Get-CIF3Token -Uri http://cif.domain.local

        # Get token information for a token with name 'readonly'
        PS C:\> Get-CIF3Token -Name 'readonly'

    .OUTPUTS
        A an array of PSCustomObjects from CIF instance's API composed of token list properties.
        Properties of each PSCustomObject are acl, admin, expires, groups, id, last_activity_at, read, token,
            username, write
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER Name
        Username to search for.
    .PARAMETER TokenToFind
        Token to search for.
        'username' or 'token'
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning a hashtable.
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/tokens.py
    #>
    [CmdletBinding()]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [string]$Name,

        [string]$TokenToFind,

        [switch]$Raw
    )

    begin {
        $Uri += '/tokens'

        $Body = @{ }

        switch($PSBoundParameters.Keys) {
            'Name'          { $Body.Add('username', $Name) }
            'TokenToFind'   { $Body.Add('token', $TokenToFind) }
        }
    }

    process {
        Write-Verbose 'Token listing from CIF API'

        $Params = @{
            Body    = $Body
            Method  = 'GET'
            Uri     = $Uri
        }

        Write-Verbose 'Adding token to request'
        $Params.Token = $Token
        Write-Verbose "Calling CIF API $Uri ..."
        
        $Response = Send-CIF3Api @Params -ErrorAction Stop
        
        if ($Raw) {
            return $Response
        } 
        else { 
            return Format-CIF3ApiResponse -InputObject $Response 
        }
    }
}