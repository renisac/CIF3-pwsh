function Get-CIF3Feed {
    <#
    .SYNOPSIS
        Gets indicator feed from CIF3 API. A feed is a filtered data-set that's been aggregated and had a whitelisted applied.
    .DESCRIPTION
        This cmdlet issues GET to the CIF API /feed endpoint to generate an indicator feed from the CIF instance. Targeted results can be returned by 
        specifying parameters.
    .EXAMPLE
        # Get indicator feed with current session token
        PS C:\> Get-CIF3Feed
        
        # Get fqdn feed using a specified token
        PS C:\> Get-CIF3Feed -Token 0000111222333456789abcdef -IType fqdn

        # Get feed of high-confidence indicators tagged as 'phishing' using a specified CIF API URI.
        PS C:\> Get-CIF3Feed -Uri http://cif.domain.local -Confidence 8 -Tag phishing -IType fqdn

        # Get a very high-confidence feed of 'malware' or 'botnet' tagged ipv4 indicators over the last 24 hours
        PS C:\> Get-CIF3Feed -IType ipv4 -Confidence 9 -Tag malware, botnet -StartTime (Get-Date).AddDays(-1) -EndTime (Get-Date)

    .OUTPUTS
        A an array of PSCustomObjects from CIF instance's API composed of indicator properties.
        Properties of each PSCustomObject are itype, cc, timezone, protocol, message, id, city, latitude, longitude, indicator, group, provider, tags,
            description, portlist, confidence, rdata, firsttime, lastttime, reporttime, asn, asn_desc, count, peers, tlp, region, and additional_data
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER Indicator
        Indicator value to pass to the API call to narrow down the search server-side.
    .PARAMETER Confidence
        Confidence value to pass to the API call to narrow down the search server-side. Only indicators >= to this value will be returned.
    .PARAMETER Provider
        Provider value to pass to the API call to narrow down the search server-side. Only indicators matching the provider will be returned.
    .PARAMETER Group
        Group value to pass to the API call to narrow down the search server-side. Only indicators matching the group will be returned.
    .PARAMETER Tag
        Tag(s) to pass to the API call to narrow down the search server-side. Only indicators matching the specified tag(s) will be returned.
    .PARAMETER ResultSize
        Limits the max number of results returned by the server to this number. Defaults to 500.
    .PARAMETER IType
        Queries for this specific indicator type (e.g., fqdn, url, ipv4, md5, etc.).
    .PARAMETER StartTime
        Limits matches to those first reported on or after this time. Must be set with EndTime. If not set, server-side only gets last 3 weeks.
    .PARAMETER EndTime
        Limits matches to those first reported on or before this time. Must be set with StartTime. If not set, server-side only gets last 3 weeks.
    .PARAMETER NoLog
        Doesn't log the query on the CIF instance.
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning custom states/errors.
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/feed/__init__.py
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [Alias('Q')]
        [string]$Indicator,

        [float]$Confidence,

        [string]$Provider,

        [string]$Group,

        [string[]]$Tag,

        [Alias('Limit')]
        [int]$ResultSize = 100,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ipv4', 'ipv6', 'fqdn', 'url', 'email', 'md5', 'sha1', 'sha256', 'sha512')]
        [string]$IType,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$StartTime,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$EndTime,

        [switch]$NoLog,

        [switch]$Raw
    )

    begin {
        $Uri += '/feed'
        
        $Body = @{ }

        if ($PSBoundParameters.ContainsKey('StartTime')) {
            # try to set datetime object to a string the API will like
            $StrStart = $StartTime.ToString("yyyy-MM-ddT00:00:00Z") # have to set start time HH:mm:ss to 00:00:00 or CIF doesn't like it
            $StrEnd = $EndTime.ToString("yyyy-MM-ddT23:59:59Z") # have to set end time HH:mm:ss to 23:59:59 or CIF isn't happy
            $ReportTime = "$StrStart,$StrEnd"
            $Body.Add('reporttime', $ReportTime) 
        }

        switch($PSBoundParameters.Keys) {
            'NoLog'         { $Body.Add('nolog', $true) }
            'Indicator'     { $Body.Add('q', $Indicator) }
            'Confidence'    { $Body.Add('confidence', $Confidence) }
            'Provider'      { $Body.Add('provider', $Provider) }
            'Group'         { $Body.Add('group', $Group) }
            'Tag'           { $Body.Add('tags', $Tag -join ',') }
            'ResultSize'    { $Body.Add('limit', $ResultSize) }
            'IType'         { $Body.Add('itype', $IType) }
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
        elseif ($null -ne $Response.data) {
                Write-Verbose 'Received response from CIF API'
                return Format-CIF3ApiResponse -InputObject $Response.data
        }
        elseif ($Response.status -eq 'failed') {
            Write-Error -Message "Connected to CIF API, but got a failed status: $($Response.message)"
        }
        else {
            Write-Error -Message "CIF API call succeeded, but responded with incorrect value: $_"
        }
    }
}