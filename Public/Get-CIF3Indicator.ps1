function Get-CIF3Indicator {
    <#
    .SYNOPSIS
        Gets indicators from CIF3 API.
    .DESCRIPTION
        This cmdlet issues GET to the CIF API /indicators endpoint to list indicators on the CIF instance. Targeted results can be returned by specifying
        parameters.
    .EXAMPLE
        # Get indicator list with current session token
        PS C:\> Get-CIF3Indicator
        
        # Get indicator list using a specified token
        PS C:\> Get-CIF3Indicator -Token 0000111222333456789abcdef

        # Get high-confidence indicator list using a specified CIF API URI.
        PS C:\> Get-CIF3Indicator -Uri http://cif.domain.local -Confidence 7.5

        # Get all indicators tagged as 'phishing', 'botnet', or 'malware' between 2 weeks and 1 week ago
        PS C:\> Get-CIF3Indicator -Tag phishing, botnet, malware -StartTime (Get-Date).AddDays(-14) -EndTime (Get-Date).AddDays(-7)

        # Get indicators tagged as 'cdn' and return results sorted first by reporttime DESC then confidence ASC.
        PS C:\> Get-CIF3Indicator -Tag 'cdn' -Sort '-reporttime', 'confidence'

        # Match indicator '44.227.178.0/24' exactly as well as any child IPs; also include parent CIDRs that contain this CIDR, or child CIDRs contained within this CIDR.
        PS C:\> Get-CIF3Indicator -Indicator '44.227.178.0/24' -IncludeRelatives

        # Return any results for specified indicator, and include additional param in API call which
        # will be added to URL parameter as "?testKey=testValue"
        # This enables passing URL parameters supported by the REST API that may not have explicit params supported by this module.
        PS C:\> Get-CIF3Indicator -Indicator 'bad.tld' -ExtraParams @{ 'testKey' = 'testValue' }

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
        Defaults to 5.
    .PARAMETER Provider
        Provider(s) to pass to the API call to narrow down the search server-side. Only indicators matching the provider(s) will be returned.
        Exclude a provider by prepending it with an exclamation mark (e.g.: !csirtg.io, !otherprovider.tld)
    .PARAMETER Group
        Group value to pass to the API call to narrow down the search server-side. Only indicators matching the group will be returned.
    .PARAMETER Tag
        Tag(s) to pass to the API call to narrow down the search server-side. Only indicators matching the specified tag(s) will be returned.
    .PARAMETER ResultSize
        Limits the max number of results returned by the server to this number. Defaults to 500.
    .PARAMETER IType
        Queries for this specific indicator type (e.g., fqdn, url, ipv4, md5, etc.).
    .PARAMETER StartTime
        Limits matches to those first reported on or after this time. Must be set with EndTime.
    .PARAMETER EndTime
        Limits matches to those first reported on or before this time. Must be set with StartTime.
    .PARAMETER NoLog
        Doesn't log the query on the CIF instance.
    .PARAMETER IncludeRelatives
        In addition to exact hits, matches and returns any relatives of a searched Indicator, e.g.,
        parent/child CIDRs for IPs.
    .PARAMETER Sort
        Backend fields by which to sort server-side before returning results.
        Defaults to '-reporttime', '-lasttime' which primary sorts reporttime DESC and secondary sorts lasttime DESC.
    .PARAMETER ExtraParams
        Additional, optional URL params for which there is not a defined cmdlet param that will be passed to CIF's API.
    .PARAMETER Raw
        Return the raw response object from the CIF API, versus parsing it and returning custom states/errors.
    .FUNCTIONALITY
        CIF3
    .LINK
        https://github.com/csirtgadgets/bearded-avenger/blob/master/cif/httpd/views/indicators.py
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param (
        [string]$Token = $Script:CIF3.Token,

        [string]$Uri = $Script:CIF3.Uri,

        [Alias('Q')]
        [string]$Indicator,

        [float]$Confidence = 5,

        [string[]]$Provider,

        [string]$Group,

        [string[]]$Tag,

        [Alias('Limit')]
        [int]$ResultSize = 500,

        [ValidateSet('ipv4', 'ipv6', 'fqdn', 'url', 'email', 'md5', 'sha1', 'sha256', 'sha512', 'ssdeep')]
        [string]$IType,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$StartTime,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$EndTime,

        [ValidateCount(1,2)]
        [string[]]$Sort,

        [hashtable]$ExtraParams,

        [switch]$NoLog,

        [switch]$IncludeRelatives,

        [switch]$Raw
    )

    begin {
        $Uri += '/indicators'
        
        $Token = Select-ClientToken -Token $Token -RequestType 'Read'
        
        $Body = @{ }

        # PSBoundParameters contains only params where value was supplied by caller, ie, does not 
        # contain default values. The following foreach loop adds all unbound params that have 
        # default values. Exclude SwitchParams so we don't add them as $false since that's redundant
        foreach ($Key in $MyInvocation.MyCommand.Parameters.Keys) {
            $Value = Get-Variable $Key -ValueOnly -ErrorAction SilentlyContinue
            if ($null -ne $Value -and -not $PSBoundParameters.ContainsKey($Key) `
                -and ($Value -isNot [System.Management.Automation.SwitchParameter]) `
                -and -not ([String]::IsNullOrWhiteSpace($Value))) { 
                $PSBoundParameters[$Key] = $Value 
            }
        }

        if ($PSBoundParameters.ContainsKey('StartTime')) {
            $ReportTime = ConvertTo-ReportTimeUTC -StartTime $StartTime -EndTime $EndTime
            $Body.Add('reporttime', $ReportTime) 
        }

        switch($PSBoundParameters.Keys) {
            'NoLog'             { $Body.Add('nolog', $NoLog) }
            'Indicator'         { $Body.Add('q', $Indicator) }
            'Confidence'        { $Body.Add('confidence', $Confidence) }
            'Provider'          { $Body.Add('provider', $Provider -join ',') }
            'Group'             { $Body.Add('group', $Group) }
            'Tag'               { $Body.Add('tags', $Tag -join ',') }
            'Sort'              { $Body.Add('sort', $Sort -join ',') }
            'ResultSize'        { $Body.Add('limit', $ResultSize) }
            'IType'             { $Body.Add('itype', $IType) }
            'IncludeRelatives'  { $Body.Add('find_relatives', $IncludeRelatives) }
            'ExtraParams'       { foreach ($Param in $ExtraParams.GetEnumerator()) {
                                  $Body.Add($Param.Key, $Param.Value)
                } 
            }
        }

    }

    process {
        Write-Verbose 'Indicator listing from CIF API'

        $Params = @{
            Body    = $Body
            Method  = 'GET'
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
}