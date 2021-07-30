function Add-CIF3Indicator {
    <#
    .SYNOPSIS
        Adds an indicator at a CIF3 API.
    .DESCRIPTION
        This cmdlet issues POST to the CIF API /indicators endpoint to add an indicator on the CIF instance. 
    .EXAMPLE
        # Add an indicator with current session token
        PS C:\> Add-CIF3Indicator -Indicator baddomain.xyz -Confidence 7 -Tag malware -TLP yellow
        
        # Add an indicator using a specified CIF API URI and specify its protocol
        PS C:\> Add-CIF3Indicator -Uri http://cif.domain.local -Indicator baddomain.xyz -Confidence 8 -Tag botnet -TLP green -Protocol UDP

        # Add an indicator and specify its Group and a Description
        PS C:\> Add-CIF3Indicator -Indicator baddomain.xyz -Confidence 8 -Tag phishing -TLP green -Group public_feeds -Description 'picked up from VirusTotal'

    .OUTPUTS
        An integer representing the number of indicators successfully added, e.g. 1
    .PARAMETER Token
        The API token to use when communicating with the CIF API (uses session token if not specified).
    .PARAMETER Uri
        The Base Uri to use for the CIF instance API (uses session Uri if not specified).
    .PARAMETER Indicator
        Indicator value to store, e.g.: baddomain.xyz.
    .PARAMETER Confidence
        Confidence value for the indicator being submitted.
    .PARAMETER TLP
        The Traffic Light Protocol value of the indicator being submitted. Used for restricting sharing.
    .PARAMETER Group
        Group to which the submitted indicator should be added.
    .PARAMETER Tag
        Tag(s) to add to the indicator being submitted.
    .PARAMETER Protocol
        Can specify the protocol used with the indicator being submitted (limited to TCP, UDP, and ICMP).
    .PARAMETER Port
        Port(s) observed being used by the indicator.
    .PARAMETER Description
        Detailed message that can be stored along with the submitted indicator.
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

        [Parameter(Mandatory = $true)]
        [Alias('Q')]
        [string]$Indicator,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 10)]
        [float]$Confidence,

        [Parameter(Mandatory = $true)]
        [string[]]$Tag,

        [Parameter(Mandatory = $true)]
        [string]$TLP,

        [ValidateSet('TCP', 'UDP', 'ICMP')]
        [string]$Protocol,

        [string]$Port,

        [string]$Group,

        [string]$Description,

        [switch]$Raw
    )

    begin {
        $Uri += '/indicators'

        $Token = Select-ClientToken -Token $Token -RequestType 'Write'

        $Body = @{ }

        switch($PSBoundParameters.Keys) {
            'Indicator'     { $Body.Add('indicator', $Indicator) }
            'Confidence'    { $Body.Add('confidence', $Confidence) }
            'Protocol'      { $Body.Add('protocol', $Protocol.ToLower()) }
            'Group'         { $Body.Add('group', $Group) }
            'Tag'           { $Body.Add('tags', $Tag -join ',') }
            'TLP'           { $Body.Add('tlp', $TLP) }
            'Port'          { $Body.Add('portlist', $Port) }
            'Description'   { $Body.Add('description', $Description) }
        }
    }

    process {
        Write-Verbose 'Creating request body'

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
}