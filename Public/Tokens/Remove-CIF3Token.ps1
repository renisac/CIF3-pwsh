function Remove-CIF3Token {
    <#
    .SYNOPSIS
        Removes a token at the given CIF3 API.
    .DESCRIPTION
        This cmdlet calls the CIF API /tokens endpoint with DELETE method to remove token(s) on the CIF instance. If multiple tokens have the same name,
        specifying the token to be deleted by username will remove all matching tokens.
    .EXAMPLE
        # Remove all token where the 'username'  is 'tokenname' while authenticating with current session token
        PS C:\> Remove-CIF3Token -Name 'tokenname'
        
        # Remove 'abcdef9999888855553333' token while authenticating using the specified '0000111222333456789abcdef' token
        PS C:\> Remove-CIF3Token -Token 0000111222333456789abcdef -Id 'abcdef9999888855553333'

        # Remove a token named 'tokentoberemoved' on a specified CIF API URI.
        PS C:\> Remove-CIF3Token -Uri http://cif.domain.local -Name 'tokentoberemoved'

    .OUTPUTS
        An int representing the number of tokens deleted. A return of '2' indicates that two tokens matched and were deleted. If '0' is returned,
        then no tokens were found or removed.
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER Name
        [string] value name of token(s) to remove. Matches any token with this name (if you have multiple tokens with same name, they'll all be removed).
    .PARAMETER Id
        [string] value tokenid of token to remove. Mutually exclusive with Name parameter.
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

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ById', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Id,

        [switch]$Raw,

        [switch]$Force
    )

    begin {

        $Uri += '/tokens'

        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $Filter = @{ username = $Name }
        }
        else {
            $Filter = @{ token = $Id}
        }

    }

    process {
        
        Write-Verbose 'Token removal on CIF API'
        
        $Params = @{
            Body    = $Filter
            Method  = 'DELETE'
            Uri     = $Uri
        }

        Write-Verbose 'Adding token to request'
        $Params.Token = $Token

        if ($Force -or $PSCmdlet.ShouldProcess($Filter.Values, 'Delete token')) {
            $Response = Send-CIF3Api @Params -ErrorAction Stop

            if ($Raw) {
                return $Response
            } elseif ($Response.message -eq 'success') {
                return Format-CIF3ApiResponse -InputObject $Response.data
            } elseif ($Response.message -eq 'failed') {
                Write-Error -Message "CIF API call failed: $Response"
            } elseif ($Response.message -eq 'missing data') {
                Write-Error -Message "CIF API call was missing some data: $Response"
            } else {
                Write-Error -Message "CIF API call succeeded, but responded with incorrect value: $_"
            }
        }
        
    }
}