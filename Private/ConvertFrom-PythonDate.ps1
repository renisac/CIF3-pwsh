function ConvertFrom-PythonDate {
    # Helper function that takes a string returned from a python datetime in the form of 2020-02-10T17:51:55.734794Z and converts it
    # to a PowerShell/.NET datetime object
    param(
        [Parameter(ValueFromPipeline = $true)]    
        [string]$Date = ''
    )

    begin {
        $Culture = [Globalization.CultureInfo]::InvariantCulture
    }
    process { 
        if (-not [string]::IsNullOrWhiteSpace($Date)) {
            # sometimes jokers use various date formats on the submitted indicators.
            # try yyyy-MM-ddTHH:mm:ss first (e.g.: 2020-02-12T08:12:23Z)
            try {
                # regardless whether we're given 0 digits of milliseconds or 6, always trim after seconds, tack on Zulu, 
                # and move on with formatting
                Write-Output ([datetime]::ParseExact($Date.Substring(0, 19) + 'Z', 'yyyy-MM-ddTHH:mm:ssZ', $Culture))
                # if this worked, jump out of func so we don't waste time on next try/catch
                return
            }
            catch { }
            # try MM/dd/yyyy HH:mm:ssZ (e.g.: 02/12/2020 08:12:23Z)
            try {
                # regardless whether we're given 0 digits of milliseconds or 6, always trim after seconds, tack on Zulu, 
                # and move on with formatting
                Write-Output ([datetime]::ParseExact($Date.Substring(0, 19) + 'Z', 'MM/dd/yyyy HH:mm:ssZ', $Culture))
            }
            catch { }
            
        }  
    }

    end { }
}