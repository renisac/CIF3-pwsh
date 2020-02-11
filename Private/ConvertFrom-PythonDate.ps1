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
        if ($null -ne $Date -and $Date -ne '') {
            Write-Output ([datetime]::ParseExact($Date, 'yyyy-MM-ddTHH:mm:ss.ffffffZ', $Culture))
        }  
    }

    end { }
}