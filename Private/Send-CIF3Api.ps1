function Send-CIF3Api {
    <#
    .SYNOPSIS
        Send a message to the CIFv3 API endpoint

    .DESCRIPTION
        Helper function that sends a message to the CIFv3 API endpoint.

        This function is used by other CIF3 functions.

    .PARAMETER Method
        CIF3 API method to call (GET, POST, DELETE, PATCH)

        Reference: https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/help.py

    .PARAMETER Headers
        Hash table of headers to send with the CIF API request

    .PARAMETER Uri
        String uri of remote CIFv3 URL endpoint to contact. Defaults to /

    .PARAMETER Token
        CIFv3 token to use

    .PARAMETER Body
        Hash table of arguments to send to the CIF API.

    .PARAMETER Proxy
        Proxy server to use

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This may expose your token in verbose output

    .FUNCTIONALITY
        CIF
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Method,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Headers = @{ },

        [Parameter()]
        [hashtable]$Body = @{ },

        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (-not $_ -and -not $Script:CIF3.Token) {
                    throw 'Please supply a CIF Token with Set-CIF3Config -Token <token>'
                }
                elseif (-not $Script:CIF3.Uri) {
                    throw 'Please supply a remote Uri with Set-CIF3Config -Uri <remote url>'
                }
                else {
                    $true
                }
            })]
        [string]$Token = $Script:CIF3.Token,

        [string]$Proxy = $Script:CIF3.Proxy,

        [string]$Uri = $Script:CIF3.Uri,

        [switch]$ForceVerbose = $Script:CIF3.ForceVerbose
    )

    begin {

        $Params = @{
            Uri         = $Uri
            ErrorAction = 'Stop'
        }
        if ($Proxy) {
            $Params.Add('Proxy', $Proxy)
        }
        if (-not $ForceVerbose) {
            $Params.Add('Verbose', $false)
        }
        if ($ForceVerbose) {
            $Params.Add('Verbose', $true)
        }
        if ($Body.Count -gt 0) {
            if ($Method -ne 'GET') {
                Write-Verbose 'Adding JSON Body'
                [string]$Body = $Body | ConvertTo-Json -Compress
            }
            $Params.Add('Body', $Body)
        }
        $Headers.Authorization = "Token token=$Token"
        $Headers.Accept = 'application/vnd.cif.v3+json'
        $Headers.'User-Agent' = "CIF3/$($MyInvocation.MyCommand.Module.Version) (PowerShell Wrapper)"

    }

    process {

        try {
            $Response = $null
            # https://stackoverflow.com/a/30415506
            $ExpandedHash = $Body | Format-Table Name, @{n='Value';e={
                if ($_.Value -is [hashtable]) {
                  $ht = $_.Value
                  $a = $ht.Keys | ForEach-Object { if ($ht[$_] -ne '') { '{0}={1}' -f $_, $ht[$_] } }
                  '{{{0}}}' -f ($a -join ', ')
                } 
                else { $_.Value }
                }} | Out-String
            Write-Verbose "Calling CIF API $Uri with params $ExpandedHash ..."
            $Response = Invoke-RestMethod @Params -Headers $Headers -Method $Method -ContentType 'application/json'
            Write-Verbose 'Received response from CIF API'
        }
        catch {
            # (HTTP 429 is "Too Many Requests")
            if ($_.Exception.Response.StatusCode -eq 429) {
    
                # Get the time before we can try again.
                if ( $_.Exception.Response.Headers -and $_.Exception.Response.Headers.Contains('Retry-After') ) {
                    $RetryPeriod = $_.Exception.Response.Headers.GetValues('Retry-After')
                    if ($RetryPeriod -is [string[]]) {
                        $RetryPeriod = [int]$RetryPeriod[0]
                    }
                }
                else {
                    $RetryPeriod = 2
                }
                Write-Verbose "Sleeping [$RetryPeriod] seconds due to CIF 429 response"
                Start-Sleep -Seconds $RetryPeriod
                Send-CIF3Api @PSBoundParameters
    
            }
            elseif ($_.Exception.Response.StatusCode -eq 401) {
                Write-Error -Exception $_.Exception -Message 'Server returned 401 Unauthorized. Check your token?'
            }
            elseif ($_.Exception.Response.StatusCode -eq 408) {
                Write-Error -Exception $_.Exception -Message 'Server returned 408 timed out. Check connection to CIF instance?'
            }
            elseif ($_.Exception.Response.StatusCode -eq 422) {
                Write-Error -Exception $_.Exception -Message 'Server returned 422 run time error. Check CIF instance logs for more info.'
            }
            elseif ($null -ne $_.ErrorDetails.Message -and $_.ErrorDetails.Message -ne '') {
                # Convert the error-message to an object. (Invoke-RestMethod will not return data by-default if a 4xx/5xx status code is generated.)
                $Message = $_.ErrorDetails.Message | ConvertFrom-Json | Select-Object -ExpandProperty 'message'
                Write-Error -Exception $_.Exception -Message "Server returned $($_.Exception.Response.StatusCode.Value__). $($Message)"
            }
            else {
                Write-Error -Exception $_.Exception -Message "Server returned $($_.Exception.Response.StatusCode.Value__). 
                CIFv3 API call failed: $_. Check remote Uri?"
            }
        }
    
        # Check to see if we have confirmation that our API call failed.
        # (Responses with exception-generating status codes are handled in the "catch" block above - this one is for errors that don't generate exceptions)
        if ($null -eq $Response) {
            Write-Error -Message "Something went wrong. `$Response is `$null"
        }
        elseif ($Response -eq '') {
            Write-Error -Message "CIF API call succeeded but response was empty"
        }
        elseif ($Response.status -eq 'failed') {
            Write-Error -Message "Connected to CIF API, but got a failed status: $($Response.message)"
        }
        elseif ($Response.message -eq 'missing data') {
            Write-Error -Message "CIF API call was missing some data: $Response"
            break
        }
        elseif ($Response) {
            Write-Output $Response
        }
        else {
            Write-Error "Something went wrong: Response is $Response"
        }

    }

    end {}
    
}