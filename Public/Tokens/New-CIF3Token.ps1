function New-CIF3Token {
    <#
    .SYNOPSIS
        Creates a token at the given CIF3 API.
    .DESCRIPTION
        This cmdlet calls the CIF API /tokens method with POST method to create token(s) on the CIF instance.
    .EXAMPLE
        # Create new admin token while authenticating with current session token
        PS C:\> New-CIF3Token -Name admin -Permission admin
        
        # Create token named 'readonly' while authenticating using a specified token
        PS C:\> New-CIF3Token -Token 0000111222333456789abcdef -Name 'readonly' -Permission Read

        # Create token named 'writeadmin' against a specified CIF API URI.
        PS C:\> New-CIF3Token -Uri http://cif.domain.local -Name 'writeadmin' -Permission admin, write

    .OUTPUTS
        A an array of PSCustomObjects from CIF instance's API composed of token list properties.
        Properties of each PSCustomObject are acl, admin, expires, groups, id, last_activity_at, read, token,
            username, write
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified)
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified)
    .PARAMETER Name
        The name to set for the new token
    .PARAMETER Group
        Group(s) to which newly created token should be added. If not specified, automatically added to 'everyone' group
    .PARAMETER Permission
        Permission(s) to apply to newly created token - can be any combination of 'Admin', 'Read', or 'Write.' If no permission
        specified, token will be created with no explicit permissions
    .PARAMETER Revoked
        Creates the token in a revoked state
    .PARAMETER Acl
        Adds this ACL to the newly created token
    .PARAMETER Expires
        Sets an expiration datetime for the newly created token
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning custom states/errors
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/tokens.py
    #>
    [CmdletBinding()]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Name to use for new token')]
        [string]$Name,

        [Parameter(HelpMessage = 'CIF group(s) to which newly created token should be added')]
        [string[]]$Group,

        [ValidateSet('Admin', 'Read', 'Write')]
        [string[]]$Permission,

        [Parameter(HelpMessage = 'Specify this parameter as $true to create the token in a revoked state')]
        [bool]$Revoked,

        [string]$Acl,

        [Parameter(HelpMessage = 'DateTime for when token should expire. Do not specify for no expiry')]
        [datetime]$Expires,

        [switch]$Raw
    )

    begin {
        $Uri += '/tokens'

        $Body = @{ 
            username = $Name
            admin  = $false
            read = $false
            write = $false
        }

        switch($PSBoundParameters.Keys) {
            'Group'     { $Body.Add('groups', $Group) }
            'Acl'       { $Body.Add('acl', $Acl) }
            'Revoked'   { $Body.Add('revoked', $Revoked) }
            'Expires'   { # try to set datetime object to a string the API will like
                            $StrExpires = $Expires.ToString("yyyy-MM-ddTHH:mm:ssZ")
                            $Body.Add('expires', $StrExpires)
            }
        }

        if ($PSBoundParameters.ContainsKey('Permission')) { 
            switch ($Permission) {
                # add each permission as is necessary if it was specified
                'Admin' { $Body['admin'] = $true }
                'Read'  { $Body['read'] = $true }
                'Write' { $Body['write'] = $true }
                default { throw "$Permission is not a supported permission value."}
            }
        }

    }

    process {
        Write-Verbose 'Token creation from CIF API'

        <# Don't need this any more, but this is a clever bit of code so I wanted to keep it :/ 
            $Body.Keys.Clone() | ForEach-Object {
                if ($null -ne $Body[$_]) {
                    # if there's a datetime in the Body, try to convert to format API will like
                    if ($Body[$_] -is [datetime]) {
                        $Body[$_] = $Body[$_].ToString("yyyy-MM-dd HH:mm:ss")
                    }
                }   
            } 
        #>

        $Params = @{
            Body    = $Body
            Method  = 'POST'
            Uri     = $Uri
        }

        Write-Verbose 'Adding token to request'
        $Params.Token = $Token
        
        $Response = Send-CIF3Api @Params -ErrorAction Stop

        if ($Raw) {
            return $Response
        } 
        else { 
            return Format-CIF3ApiResponse -InputObject $Response 
        }
       
    }

    end {}
}