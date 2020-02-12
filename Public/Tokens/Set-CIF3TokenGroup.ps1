function Set-CIF3TokenGroup {
    <#
    .SYNOPSIS
        Configures a group for the specified token at the given CIF3 API.
    .DESCRIPTION
        This cmdlet calls the CIF API /tokens endpoint with PATCH method to configure a token on the CIF instance. Currently, CIFv3 only supports
        updating a token's group (no other properties). Additionally, specified groups replace any existing groups. However, stub params have been 
        left in place in hopes that future improvements in CIF will enable further update functionality.
    .EXAMPLE
        # Configure group of token abcdef9999888855553333 to be 'cif_admins'
        PS C:\> Set-CIF3Token -Id abcdef9999888855553333 -Group 'cif_admins'

    .OUTPUTS
        Boolean True/False representing whether the update was successful
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER Id
        Tokenid of token to configure.
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning a hashtable.
    .PARAMETER Force
        Don't require $Confirm:$false, but Force completing the delete request
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/tokens.py
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Id,

        [Parameter(HelpMessage = 'CIF group(s) to which token should be added')]
        [string[]]$Group,

        <#
        [Parameter(HelpMessage = 'Specify this parameter as $true to create the token in a revoked state')]
        [bool]$Revoked,

        [string]$Acl,

        [Parameter(HelpMessage = 'DateTime for when token should expire. Do not specify for no expiry')]
        [datetime]$Expires,

        [switch]$Read,

        [switch]$Write,

        [switch]$Admin,
        #>

        [switch]$Raw,

        [switch]$Force
    )

    begin {

        $Uri += '/tokens'

        $Body = @{ token = $Id }

        switch($PSBoundParameters.Keys) {
            'Group'     { $Body.Add('groups', $Group) }
            'Acl'       { $Body.Add('acl', $Acl) }
            'Read'      { $Body.Add('read', $Read) }
            'Write'     { $Body.Add('write', $Write) }
            'Admin'     { $Body.Add('admin', $Admin) }
            'Revoked'   { $Body.Add('revoked', $Revoked) }
            'Expires'   { # try to set datetime object to a string the API will like
                            $StrExpires = $Expires.ToString("yyyy-MM-ddTHH:mm:ssZ")
                            $Body.Add('expires', $StrExpires)
            }
        }

    }

    process {
        
        Write-Verbose 'Token removal on CIF API'
        
        $Params = @{
            Body    = $Body
            Method  = 'PATCH'
            Uri     = $Uri
        }

        Write-Verbose 'Adding token to request'
        $Params.Token = $Token

        if ($Force -or $PSCmdlet.ShouldProcess($Body.Values, 'Delete token')) {
            $Response = Send-CIF3Api @Params -ErrorAction Stop

            if ($Raw) {
                return $Response
            } 
            else { 
                return Format-CIF3ApiResponse -InputObject $Response 
            }
            
        }
        
    }
}