function ConvertTo-ReportTimeUTC {
    # Helper function that takes two DateTime objects (StartTime and EndTime) and
    # standardizes to UTC before returning a comma-separated string of the values
    param(
        [Parameter(Mandatory = $true)]    
        [datetime]$StartTime,

        [Parameter(Mandatory = $true)]
        [datetime]$EndTime
    )

    begin { }

    process { 
        # try to set datetime object to a string the API will like
        $StrStart = $StartTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $StrEnd = $EndTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $ReportTime = "$StrStart,$StrEnd"
        
        Write-Verbose "Formatting time boundaries. ReportTime set to $ReportTime"
        Write-Output $ReportTime
    }

    end { }
}