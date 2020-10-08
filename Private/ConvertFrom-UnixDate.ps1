function ConvertFrom-UnixDate {
    # Helper function that takes a string in unix epoch format like '1581441970' and converts it
    # to a PowerShell/.NET datetime object. https://stackoverflow.com/a/21234844
    param(
        [Parameter(ValueFromPipeline = $true)]    
        [string]$Date = ''
    )

    begin { }

    process { 
        if (-not [string]::IsNullOrWhiteSpace($Date)) {
            Write-Output ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Date)))
        }  
    }

    end { }
}