function Get-CIF3Feed {
    <#
    .SYNOPSIS
        Gets indicator feed from CIF3 API. A feed is a filtered data-set that's been aggregated, deduplicated, and filtered through an allowlist.
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

        # Return feed of high-confidence md5 hashes tagged as 'malware,' 
        # and include additional param in API call which will be added to URL parameter as "?testKey=testValue"
        # This enables passing URL parameters supported by the REST API that may not have explicit params supported by this module.
        PS C:\> Get-CIF3Feed -Confidence 8 -Tag malware -IType md5 -ExtraParams @{ 'testKey' = 'testValue' }

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
        Limits matches to those first reported on or after this time. Must be set with EndTime. If not set, server-side only gets last 3 weeks.
    .PARAMETER EndTime
        Limits matches to those first reported on or before this time. Must be set with StartTime. If not set, server-side only gets last 3 weeks.
    .PARAMETER ExtraParams
        Additional, optional URL params for which there is not a defined cmdlet param that will be passed to CIF's API.
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

        [float]$Confidence = 5,

        [string[]]$Provider,

        [string]$Group,

        [string[]]$Tag,

        [Alias('Limit')]
        [int]$ResultSize = 50000,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ipv4', 'ipv6', 'fqdn', 'url', 'email', 'md5', 'sha1', 'sha256', 'sha512', 'ssdeep')]
        [string]$IType,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$StartTime,

        [Parameter(ParameterSetName = 'ReportTime', Mandatory = $true)]
        [datetime]$EndTime,

        [hashtable]$ExtraParams,

        [switch]$NoLog,

        [switch]$Raw
    )

    begin {
        $Uri += '/feed'
        
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
            'NoLog'             { $Body.Add('nolog', $true) }
            'Indicator'         { $Body.Add('q', $Indicator) }
            'Confidence'        { $Body.Add('confidence', $Confidence) }
            'Provider'          { $Body.Add('provider', $Provider -join ',') }
            'Group'             { $Body.Add('group', $Group) }
            'Tag'               { $Body.Add('tags', $Tag -join ',') }
            'ResultSize'        { $Body.Add('limit', $ResultSize) }
            'IType'             { $Body.Add('itype', $IType) }
            'ExtraParams'       { foreach ($Param in $ExtraParams.GetEnumerator()) {
                                  $Body.Add($Param.Key, $Param.Value)
                } 
            }
        }
    }

    process {
        Write-Verbose 'Creating request body'

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